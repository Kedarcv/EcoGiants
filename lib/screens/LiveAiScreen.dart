import 'dart:async';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/services/api_service.dart';
import 'package:deep_waste/services/livekit_config.dart';
import 'package:deep_waste/services/livekit_room_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

/// ---------------------------------------------------------------------
/// Live AI Tutor — Voice-only conversation with the EcoBot agent.
///
/// The agent (Python LiveKit worker) handles:
///   • Speech-to-text (student's mic → text)
///   • LLM reasoning (NVIDIA Llama)
///   • Text-to-speech (response → audio track)
///
/// This screen just:
///   • Connects to LiveKit with a JWT
///   • Enables the local mic
///   • Subscribes to the agent's audio track
///   • Shows UI state (connecting / listening / agent speaking)
/// ---------------------------------------------------------------------

enum AgentUiState { idle, connecting, listening, agentSpeaking, error }

class LiveAiScreen extends StatefulWidget {
  static const String routeName = '/live_ai';
  final bool cameraOn;
  final bool microphoneOn;

  const LiveAiScreen({
    super.key,
    this.cameraOn = true,
    this.microphoneOn = true,
  });

  @override
  State<LiveAiScreen> createState() => _LiveAiScreenState();
}

class _LiveAiScreenState extends State<LiveAiScreen>
    with SingleTickerProviderStateMixin {
  final LiveKitRoomService _roomService = LiveKitRoomService();

  AgentUiState _state = AgentUiState.idle;
  bool _micEnabled = true;
  String _statusText = 'Tap the button to talk to Eco';
  String? _errorText;

  // Pulse animation for agent speaking
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _roomService.addListener(_onRoomEvent);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _roomService.removeListener(_onRoomEvent);
    _roomService.dispose();
    super.dispose();
  }

  void _onRoomEvent() {
    if (!mounted) return;

    if (_roomService.isConnected) {
      // Check if any remote participant (the agent) is speaking
      final agentSpeaking = _roomService.participants.any(
        (p) => p != _roomService.localParticipant && p.isSpeaking,
      );

      setState(() {
        if (agentSpeaking) {
          _state = AgentUiState.agentSpeaking;
          _statusText = 'Eco is speaking…';
        } else if (_state != AgentUiState.connecting &&
            _state != AgentUiState.error) {
          _state = AgentUiState.listening;
          _statusText = 'Listening — ask Eco anything!';
        }
      });
    } else if (!_roomService.isConnecting && _state != AgentUiState.idle) {
      setState(() {
        _state = AgentUiState.idle;
        _statusText = 'Call ended';
      });
    }
  }

  // ── Connect / Disconnect ──────────────────────────────────────

  Future<bool> _ensureMicPermission() async {
    var status = await Permission.microphone.status;

    if (status.isGranted) return true;

    status = await Permission.microphone.request();

    if (status.isGranted) return true;

    return false;
  }

  Future<void> _connect() async {
    setState(() {
      _state = AgentUiState.connecting;
      _statusText = 'Connecting to Eco…';
      _errorText = null;
    });

    if (!await _ensureMicPermission()) {
      final granted = await _showPermissionDialogAndRequest();
      if (!granted) {
        setState(() {
          _state = AgentUiState.error;
          _errorText = 'Microphone permission is required to talk to Eco.';
        });
        return;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final studentNumber = prefs.getString('student_number') ?? 'anonymous';

      final creds = await ApiService.instance.getLiveKitToken(
        studentNumber: studentNumber,
      );

      if (creds == null) {
        setState(() {
          _state = AgentUiState.error;
          _errorText = 'Could not connect to server. Please try again.';
        });
        return;
      }

      await _roomService.connect(
        url: creds['url'] ?? LiveKitConfig.wsUrl,
        token: creds['token'],
        roomName: creds['room'] ?? 'eco-giant-room',
        participantName: 'student-$studentNumber',
        micEnabled: widget.microphoneOn,
      );

      if (_roomService.isConnected) {
        setState(() {
          _state = AgentUiState.listening;
          _micEnabled = widget.microphoneOn;
          _statusText = 'Say hello to Eco!';
        });
      } else if (_roomService.errorMessage != null) {
        setState(() {
          _state = AgentUiState.error;
          _errorText = _roomService.errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _state = AgentUiState.error;
        _errorText = 'Connection failed: $e';
      });
    }
  }

  Future<void> _toggleMic() async {
    await _roomService.toggleMicrophone();
    setState(() {
      _micEnabled = !_micEnabled;
    });
  }

  /// Shows a dialog to request microphone permission and returns true if granted
  Future<bool> _showPermissionDialogAndRequest() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission'),
        content: const Text('This app needs microphone access to function. Tap "Allow" to enable.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final status = await Permission.microphone.request();
              Navigator.pop(context, status.isGranted);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
            ),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _disconnect() async {
    await _roomService.disconnect();
    if (mounted) {
      setState(() {
        _state = AgentUiState.idle;
        _statusText = 'Tap the button to talk to Eco';
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final connected =
        _state == AgentUiState.listening || _state == AgentUiState.agentSpeaking;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(),

            // Main area — avatar + status
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAgentAvatar(),
                    const SizedBox(height: 32),
                    Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorText!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom controls
            _buildControls(connected),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () async {
              await _disconnect();
              if (mounted) Navigator.pop(context);
            },
          ),
          const Expanded(
            child: Text(
              'Eco — Waste Sorting Tutor',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Connection indicator
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _roomService.isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_roomService.isConnected ? Colors.green : Colors.red)
                      .withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentAvatar() {
    final speaking = _state == AgentUiState.agentSpeaking;
    final connecting = _state == AgentUiState.connecting;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = speaking ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: speaking ? 160 : 130,
        height: speaking ? 160 : 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0D9488),
              speaking ? const Color(0xFF14B8A6) : const Color(0xFF0F766E),
            ],
          ),
          boxShadow: [
            if (speaking)
              BoxShadow(
                color: const Color(0xFF14B8A6).withOpacity(0.5),
                blurRadius: 32,
                spreadRadius: 4,
              )
            else
              BoxShadow(
                color: const Color(0xFF0D9488).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
          ],
        ),
        child: connecting
            ? const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Icon(
                Icons.eco,
                size: 56,
                color: Colors.white,
              ),
      ),
    );
  }

  Widget _buildControls(bool connected) {
    return Container(
      padding: const EdgeInsets.only(bottom: 48, left: 24, right: 24),
      child: !connected
          ? SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed:
                    _state == AgentUiState.connecting ? null : _connect,
                icon: const Icon(Icons.mic, size: 24),
                label: Text(
                  _state == AgentUiState.connecting
                      ? 'Connecting…'
                      : 'Start talking to Eco',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mic toggle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _micEnabled
                        ? const Color(0xFF1E293B)
                        : Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _micEnabled
                          ? const Color(0xFF0D9488)
                          : Colors.red.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    onPressed: _toggleMic,
                    icon: Icon(
                      _micEnabled ? Icons.mic : Icons.mic_off,
                      color: _micEnabled ? const Color(0xFF0D9488) : Colors.red,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                // End call
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _disconnect,
                    icon: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
