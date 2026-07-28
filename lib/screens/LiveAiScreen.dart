import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/services/gemini_live_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart' hide AudioSource;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AgentUiState { idle, connecting, listening, agentSpeaking, error }

class LiveAiScreen extends StatefulWidget {
  static const String routeName = '/live_ai';
  final bool microphoneOn;

  const LiveAiScreen({
    super.key,
    this.microphoneOn = true,
  });

  @override
  State<LiveAiScreen> createState() => _LiveAiScreenState();
}

class _LiveAiScreenState extends State<LiveAiScreen>
    with SingleTickerProviderStateMixin {
  final GeminiLiveService _geminiService = GeminiLiveService();
  final AudioPlayer _player = AudioPlayer();

  AgentUiState _state = AgentUiState.idle;
  bool _micEnabled = true;
  String _statusText = 'Tap the button to talk to Eco';
  String? _errorText;
  StreamSubscription<Map<String, dynamic>>? _eventSub;

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

    _eventSub = _geminiService.events.listen(_onEvent);
    _geminiService.audioOutput.listen(_onAudioOutput);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _eventSub?.cancel();
    _geminiService.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _onAudioOutput(Uint8List data) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/eco_${DateTime.now().millisecondsSinceEpoch}.wav');
      await file.writeAsBytes(data);
      await _player.setAudioSource(AudioSource.file(file.path));
      _player.play();
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  void _onEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    final type = event['type'] as String?;
    setState(() {
      if (type == 'user') {
        _statusText = 'You said: ${event['text']}';
      } else if (type == 'gemini') {
        _state = AgentUiState.agentSpeaking;
        _statusText = 'Eco: ${event['text']}';
      } else if (type == 'turn_complete') {
        _state = AgentUiState.listening;
      } else if (type == 'interrupted') {
        _state = AgentUiState.listening;
      } else if (type == 'error') {
        _state = AgentUiState.error;
        _errorText = event['error'] as String?;
      }
    });
  }

  Future<bool> _ensureMicPermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;
    status = await Permission.microphone.request();
    return status.isGranted;
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

      await _geminiService.connect(studentNumber: studentNumber)
          .timeout(const Duration(seconds: 20));

      if (_geminiService.isConnected) {
        setState(() {
          _state = AgentUiState.listening;
          _micEnabled = widget.microphoneOn;
          _statusText = 'Say hello to Eco!';
        });
      } else if (_geminiService.errorMessage != null) {
        setState(() {
          _state = AgentUiState.error;
          _errorText = _geminiService.errorMessage;
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
    _micEnabled = !_micEnabled;
    setState(() {});
  }

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
    await _player.stop();
    await _geminiService.disconnect();
    if (mounted) {
      setState(() {
        _state = AgentUiState.idle;
        _statusText = 'Tap the button to talk to Eco';
      });
    }
  }

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
            _buildTopBar(),
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
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _geminiService.isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_geminiService.isConnected ? Colors.green : Colors.red)
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
