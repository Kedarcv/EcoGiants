import 'dart:async';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/services/livekit_room_service.dart';
import 'package:deep_waste/services/nvidia_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../components/ecobot_character.dart';

/// Live AI Tutor — Voice-Activated Full Video Experience with Duolingo-style EcoBot
///
/// Features:
///   • Full-screen video with proper rendering
///   • Voice-activated responses (tap mic to speak)
///   • Animated EcoBot character that changes poses based on state
///   • Visual feedback with animations when AI listens/responds
///   • Minimal UI - focus on conversation
///   • Floating action button for quick help/prompts
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
    with TickerProviderStateMixin {
  late final LiveKitRoomService _roomService;
  final _chatService = NvidiaChatService();
  final _tts = FlutterTts();

  // Voice interaction state
  bool _isListening = false;
  bool _isAiResponding = false;
  String _currentResponse = '';
  String _lastUserQuestion = '';
  
  // EcoBot character pose based on state
  EcoBotPose _ecobotPose = EcoBotPose.waving;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  // Show/hide UI elements
  bool _showControls = true;
  bool _showPrompts = false;
  
  // Quick educational prompts (Duolingo-style lessons)
  final List<Map<String, String>> _educationalPrompts = [
    {'question': 'What bin does plastic go in?', 'lesson': 'recycling_basics'},
    {'question': 'Tell me about composting', 'lesson': 'composting_101'},
    {'question': 'How do I dispose of e-waste?', 'lesson': 'ewaste_safety'},
    {'question': 'Quiz me on waste sorting!', 'lesson': 'quiz_mode'},
    {'question': 'Give me a fun eco fact!', 'lesson': 'eco_facts'},
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Pulse animation for listening state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Glow animation for AI responding
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _roomService = LiveKitRoomService();
    _roomService.addListener(_onRoomEvent);
    _connectToRoom();
    
    // Initialize TTS
    _initTTS();
  }
  
  void _initTTS() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _tts.stop();
    _roomService.removeListener(_onRoomEvent);
    _roomService.dispose();
    super.dispose();
  }

  void _onRoomEvent() {
    if (mounted) setState(() {});
  }

  Future<void> _connectToRoom() async {
    await _roomService.connect(
      roomName: 'eco-giants-tutor-room',
      participantName: 'eco-student',
    );

    if (_roomService.isConnected) {
      // Welcome message with TTS
      final welcomeMsg = "Hi! I'm EcoBot, your waste sorting tutor. Tap the mic and ask me anything!";
      setState(() => _currentResponse = welcomeMsg);
      await _speak(welcomeMsg);
      
      // Adjust initial camera/mic state based on Prejoin choices
      if (!widget.cameraOn) {
        await _roomService.toggleCamera();
      }
      if (!widget.microphoneOn) {
        await _roomService.toggleMicrophone();
      }
    }
  }

  // ── Voice Interaction ───────────────────────────────────────────

  /// Handle voice input - simulate voice recognition
  Future<void> _handleVoiceInput() async {
    if (_isAiResponding) return;
    
    setState(() {
      _isListening = true;
      _showPrompts = false;
      _ecobotPose = EcoBotPose.listening; // Change to listening pose
    });
    
    // Simulate listening delay (in production, use actual speech recognition)
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // For demo: use a random prompt
    final randomPrompt = _educationalPrompts[DateTime.now().millisecond % _educationalPrompts.length];
    final userQuestion = randomPrompt['question']!;
    
    setState(() {
      _isListening = false;
      _lastUserQuestion = userQuestion;
      _isAiResponding = true;
      _ecobotPose = EcoBotPose.teaching; // Change to teaching pose for response
    });
    
    await _processQuestion(userQuestion);
  }

  Future<void> _processQuestion(String question) async {
    try {
      final buffer = StringBuffer();
      await for (final chunk in _chatService.sendMessage(question)) {
        buffer.write(chunk);
        setState(() => _currentResponse = buffer.toString());
      }
      final fullReply = buffer.toString();
      
      if (fullReply.isNotEmpty) {
        await _speak(fullReply);
      }
    } catch (e) {
      setState(() => _currentResponse = "Sorry, I had trouble understanding. Can you try again?");
      await _speak("Sorry, I had trouble understanding. Can you try again?");
    } finally {
      if (mounted) {
        setState(() {
          _isAiResponding = false;
          _ecobotPose = EcoBotPose.waving; // Return to waving pose
        });
      }
    }
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  void _togglePrompts() {
    setState(() => _showPrompts = !_showPrompts);
  }

  void _selectPrompt(Map<String, String> prompt) {
    final question = prompt['question']!;
    setState(() {
      _lastUserQuestion = question;
      _isAiResponding = true;
      _showPrompts = false;
      _ecobotPose = EcoBotPose.teaching; // Change to teaching pose
    });
    _processQuestion(question);
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // Main video area
            _buildVideoArea(),

            // Top status bar
            _buildStatusBar(),

            // Response overlay (when AI is speaking)
            if (_isAiResponding || _currentResponse.isNotEmpty)
              _buildResponseOverlay(),

            // Listening indicator
            if (_isListening) _buildListeningIndicator(),

            // Prompts panel
            if (_showPrompts) _buildPromptsPanel(),

            // Control bar (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildControlBar(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Video Area ───────────────────────────────────────────────

  Widget _buildVideoArea() {
    final local = _roomService.localParticipant;
    final remoteParticipants = _roomService.room.remoteParticipants.values.toList();

    if (!_roomService.isConnected) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Colors.teal,
                strokeWidth: 4,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Connecting to EcoBot…',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    // Remote participant (AI Bot) or waiting
    if (remoteParticipants.isEmpty) {
      // Show local camera with waiting message
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildLocalVideo(local),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/images/recycle.png',
                    width: 80,
                    height: 80,
                    repeat: true,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Waiting for EcoBot to join…',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the mic to start learning!',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Two participants — AI bot takes full screen, local in corner
    return Stack(
      fit: StackFit.expand,
      children: [
        // Remote (AI Bot) - Full screen
        _buildRemoteVideo(remoteParticipants.first),
        // Local (Student) - Picture in picture
        Positioned(
          top: 80,
          right: 16,
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _buildLocalVideoSmall(local),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalVideo(lk.LocalParticipant? participant) {
    final videoPub = participant?.videoTrackPublications.firstOrNull;
    final videoTrack = videoPub?.track as lk.VideoTrack?;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (videoTrack != null && !(videoPub?.muted ?? true))
            lk.VideoTrackRenderer(
              videoTrack,
              fit: lk.VideoViewFit.cover,
            )
          else
            const Center(
              child: Icon(Icons.videocam_off, color: Colors.white38, size: 64),
            ),
        ],
      ),
    );
  }

  Widget _buildLocalVideoSmall(lk.LocalParticipant? participant) {
    final videoPub = participant?.videoTrackPublications.firstOrNull;
    final videoTrack = videoPub?.track as lk.VideoTrack?;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (videoTrack != null && !(videoPub?.muted ?? true))
            lk.VideoTrackRenderer(
              videoTrack,
              fit: lk.VideoViewFit.cover,
            )
          else
            const Center(
              child: Icon(Icons.person, color: Colors.white38, size: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildRemoteVideo(lk.RemoteParticipant participant) {
    final videoPub = participant.videoTrackPublications.firstOrNull;
    final videoTrack = videoPub?.track as lk.VideoTrack?;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (videoTrack != null && !(videoPub?.muted ?? true))
            lk.VideoTrackRenderer(
              videoTrack,
              fit: lk.VideoViewFit.cover,
            )
          else
            // Duolingo-style EcoBot character with dynamic poses
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EcoBotCharacter(
                    pose: _ecobotPose,
                    size: 180,
                    animated: true,
                  ),
                  const SizedBox(height: 24),
                  // Character name label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _ecobotPose == EcoBotPose.celebrating ? Icons.emoji_events : 
                          _ecobotPose == EcoBotPose.listening ? Icons.hearing : 
                          _ecobotPose == EcoBotPose.teaching ? Icons.school : Icons.eco,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _ecobotPose == EcoBotPose.celebrating ? 'Great job!' :
                          _ecobotPose == EcoBotPose.listening ? 'I\'m listening...' :
                          _ecobotPose == EcoBotPose.teaching ? 'Let me teach you!' :
                          'EcoBot AI Tutor',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // AI Bot name label (bottom)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.eco,
                      color: Colors.teal,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'EcoBot AI Tutor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Bar ───────────────────────────────────────────────

  Widget _buildStatusBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () async {
                  await _roomService.disconnect();
                  if (mounted) Navigator.pop(context);
                },
              ),
              const Expanded(
                child: Text(
                  'EcoBot Live Tutor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Connection dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _roomService.isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_roomService.isConnected ? Colors.green : Colors.red).withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ── Response Overlay ─────────────────────────────────────────

  Widget _buildResponseOverlay() {
    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isAiResponding ? Colors.teal.withOpacity(0.5) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      PhosphorIcons.robot,
                      color: Colors.teal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _lastUserQuestion.isEmpty ? 'Your Question' : _lastUserQuestion,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentResponse,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isAiResponding) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'EcoBot is speaking…',
                      style: TextStyle(
                        color: Colors.teal.withOpacity(0.8),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Listening Indicator ──────────────────────────────────────

  Widget _buildListeningIndicator() {
    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 200 * _pulseAnimation.value,
              height: 200 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.teal.withOpacity(0.3),
                    Colors.teal.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIcons.microphone,
                      color: Colors.teal,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Listening…',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ask me anything!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Prompts Panel ────────────────────────────────────────────

  Widget _buildPromptsPanel() {
    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    PhosphorIcons.lightbulb,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Try asking:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: _togglePrompts,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _educationalPrompts.map((prompt) {
                  return ActionChip(
                    backgroundColor: Colors.teal.withOpacity(0.2),
                    side: BorderSide(color: Colors.teal.withOpacity(0.3)),
                    avatar: const Icon(
                      PhosphorIcons.chatTeardrop,
                      color: Colors.teal,
                      size: 18,
                    ),
                    label: Text(
                      prompt['question']!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    onPressed: () => _selectPrompt(prompt),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Control Bar ──────────────────────────────────────────────

  Widget _buildControlBar() {
    final local = _roomService.localParticipant;
    final micEnabled = local?.isMicrophoneEnabled() ?? false;
    final camEnabled = local?.isCameraEnabled() ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.9), Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mic button (primary action)
            _controlButton(
              icon: _isListening ? Icons.mic : (micEnabled ? Icons.mic : Icons.mic_off),
              label: _isListening ? 'Listening' : (micEnabled ? 'Mute' : 'Unmute'),
              isActive: micEnabled || _isListening,
              isPrimary: true,
              isPulsing: _isListening,
              onTap: _isListening ? null : _handleVoiceInput,
            ),
            
            // Camera toggle
            _controlButton(
              icon: camEnabled ? Icons.videocam : Icons.videocam_off,
              label: camEnabled ? 'Camera' : 'Camera Off',
              isActive: camEnabled,
              onTap: _roomService.toggleCamera,
            ),
            
            // Switch camera
            _controlButton(
              icon: Icons.flip_camera_ios,
              label: 'Switch',
              isActive: true,
              onTap: _roomService.switchCamera,
            ),
            
            // Prompts button
            _controlButton(
              icon: Icons.lightbulb_outline,
              label: 'Help',
              isActive: _showPrompts,
              color: Colors.amber,
              onTap: _togglePrompts,
            ),
            
            // Leave call
            _controlButton(
              icon: Icons.call_end,
              label: 'Leave',
              isActive: false,
              color: Colors.red,
              onTap: () async {
                await _roomService.disconnect();
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onTap,
    Color? color,
    bool isPrimary = false,
    bool isPulsing = false,
  }) {
    Widget buttonContent = Container(
      width: isPrimary ? 64 : 52,
      height: isPrimary ? 64 : 52,
      decoration: BoxDecoration(
        color: color ??
            (isActive ? Colors.white.withOpacity(0.2) : Colors.red.withOpacity(0.8)),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: isPrimary ? 28 : 24),
    );

    if (isPulsing) {
      buttonContent = AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: buttonContent,
      );
    }

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buttonContent,
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
