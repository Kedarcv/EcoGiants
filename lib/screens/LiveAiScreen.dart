import 'dart:async';
import 'dart:convert';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/services/livekit_room_service.dart';
import 'package:deep_waste/services/nvidia_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

/// Live AI Tutor — Full WebRTC Room using official livekit_client SDK.
///
/// Layout pattern based on livekit_components-flutter example:
///   • Top: status bar + leave button
///   • Middle: video grid (local student + AI agent video)
///   • Bottom: control bar (mic, cam, switch, chat toggle)
///   • Overlay: chat panel with NVIDIA LLM responses + TTS
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

  // Chat state
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatBubble> _messages = [];
  bool _isAiResponding = false;
  bool _showChat = true;

  // Animated dots
  late AnimationController _dotsController;

  // Quick prompts
  final List<String> _quickPrompts = [
    'What bin does this go in?',
    'Why is recycling important?',
    'How do I dispose of batteries?',
    'Can I compost this?',
    'Fun fact about waste!',
  ];

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _roomService = LiveKitRoomService();
    _roomService.addListener(_onRoomEvent);
    _connectToRoom();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _textController.dispose();
    _scrollController.dispose();
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
      _addSystemMessage(
        'Connected to EcoBot! Ask me anything about waste sorting.',
        isBot: true,
      );

      // Adjust initial camera/mic state based on Prejoin choices
      if (!widget.cameraOn) {
        await _roomService.toggleCamera();
      }
      if (!widget.microphoneOn) {
        await _roomService.toggleMicrophone();
      }
    }
  }

  // ── Messaging + AI ───────────────────────────────────────────

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    _addMessage(text, isUser: true);
    setState(() => _isAiResponding = true);

    try {
      final buffer = StringBuffer();
      await for (final chunk in _chatService.sendMessage(text)) {
        buffer.write(chunk);
        _updateLastBotMessage(buffer.toString());
      }
      final fullReply = buffer.toString();
      if (fullReply.isNotEmpty) {
        await _speak(fullReply);
      }
    } catch (e) {
      _addSystemMessage('Error: $e', isBot: true);
    } finally {
      if (mounted) setState(() => _isAiResponding = false);
    }
  }

  Future<void> _speak(String text) async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.05);
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);
  }

  void _addMessage(String text, {required bool isUser}) {
    setState(() {
      _messages.add(_ChatBubble(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _addSystemMessage(String text, {bool isBot = false}) {
    setState(() {
      _messages.add(_ChatBubble(
        text: text,
        isUser: false,
        isSystem: !isBot,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _updateLastBotMessage(String text) {
    if (_messages.isEmpty) return;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (!_messages[i].isUser && !_messages[i].isSystem) {
        setState(() {
          _messages[i] = _ChatBubble(
            text: text,
            isUser: false,
            timestamp: _messages[i].timestamp,
          );
        });
        return;
      }
    }
    setState(() {
      _messages.add(_ChatBubble(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

            // Control bar (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildControlBar(),
            ),

            // Chat overlay
            if (_showChat) _buildChatOverlay(),
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
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 16),
            Text(
              'Connecting to EcoBot…',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Single participant (student solo) or two-up (student + AI)
    if (remoteParticipants.isEmpty) {
      // Solo — just show local camera full screen with a waiting message
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildLocalVideo(local),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Waiting for EcoBot to join…',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }

    // Two participants — grid layout
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: _buildRemoteVideo(remoteParticipants.first),
        ),
        Expanded(
          flex: 1,
          child: _buildLocalVideo(local),
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
              child: Icon(Icons.videocam_off, color: Colors.white38, size: 48),
            ),
          // Name label
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'You',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
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
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.smart_toy, color: Colors.teal, size: 64),
                  SizedBox(height: 12),
                  Text(
                    'EcoBot',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            ),
          // Name label
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.eco, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'EcoBot AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _roomService.isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Chat toggle
              IconButton(
                icon: Icon(
                  _showChat ? Icons.chat_bubble : Icons.chat_bubble_outline,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _showChat = !_showChat),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _controlButton(
              icon: micEnabled ? Icons.mic : Icons.mic_off,
              label: micEnabled ? 'Mute' : 'Unmute',
              isActive: micEnabled,
              onTap: _roomService.toggleMicrophone,
            ),
            _controlButton(
              icon: camEnabled ? Icons.videocam : Icons.videocam_off,
              label: camEnabled ? 'Camera' : 'Camera Off',
              isActive: camEnabled,
              onTap: _roomService.toggleCamera,
            ),
            _controlButton(
              icon: Icons.flip_camera_ios,
              label: 'Switch',
              isActive: true,
              onTap: _roomService.switchCamera,
            ),
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
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color ??
                  (isActive ? Colors.white.withOpacity(0.2) : Colors.red.withOpacity(0.8)),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Chat Overlay ─────────────────────────────────────────────

  Widget _buildChatOverlay() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.45,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Quick prompts
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ActionChip(
                    backgroundColor: Colors.teal.shade800,
                    side: BorderSide(color: Colors.teal.shade600),
                    label: Text(
                      _quickPrompts[index],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    onPressed: () => _sendMessage(_quickPrompts[index]),
                  );
                },
              ),
            ),

            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _buildBubble(_messages[index]),
              ),
            ),

            // Typing indicator
            if (_isAiResponding) _buildTypingIndicator(),

            // Input bar
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: !_isAiResponding,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (text) => _sendMessage(text),
                      decoration: InputDecoration(
                        hintText: 'Ask EcoBot…',
                        hintStyle: TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF334155),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _isAiResponding
                        ? null
                        : () => _sendMessage(_textController.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isAiResponding
                            ? Colors.grey.shade700
                            : Colors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isAiResponding ? Icons.hourglass_top : Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(_ChatBubble msg) {
    if (msg.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade700,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
      );
    }

    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.teal.shade600 : const Color(0xFF334155),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco, size: 12, color: Colors.teal),
                  const SizedBox(width: 4),
                  Text(
                    'EcoBot',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(11),
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade300,
                    ),
                  ),
                ],
              ),
            if (!isUser) const SizedBox(height: 4),
            Text(
              msg.text,
              style: TextStyle(
                fontSize: getProportionateScreenWidth(14),
                color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.eco, size: 14, color: Colors.teal),
          const SizedBox(width: 6),
          AnimatedBuilder(
            animation: _dotsController,
            builder: (context, child) {
              final dots = ((_dotsController.value * 3).floor() % 3) + 1;
              return Text(
                'EcoBot is thinking${"." * dots}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Chat bubble model ──────────────────────────────────────────

class _ChatBubble {
  final String text;
  final bool isUser;
  final bool isSystem;
  final DateTime timestamp;

  _ChatBubble({
    required this.text,
    this.isUser = false,
    this.isSystem = false,
    required this.timestamp,
  });
}
