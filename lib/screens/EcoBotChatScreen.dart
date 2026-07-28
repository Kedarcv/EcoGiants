import 'dart:async';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/services/nvidia_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class EcoBotChatScreen extends StatefulWidget {
  static const String routeName = '/ecobot_chat';

  const EcoBotChatScreen({super.key});

  @override
  State<EcoBotChatScreen> createState() => _EcoBotChatScreenState();
}

class _EcoBotChatScreenState extends State<EcoBotChatScreen>
    with SingleTickerProviderStateMixin {
  final NvidiaChatService _chatService = NvidiaChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _tts = FlutterTts();

  final List<_ChatBubble> _messages = [];
  bool _isAiResponding = false;
  bool _ttsEnabled = false;

  late AnimationController _dotsController;

  final List<String> _quickPrompts = [
    'What bin does a plastic bottle go in?',
    'Why is recycling important?',
    'How do I dispose of batteries?',
    'Can I compost fruit peels?',
    'Give me a fun fact about waste!',
    'How do I reduce single-use plastic?',
  ];

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _tts.stop();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(_ChatBubble(
        text:
            "Hi there! I'm EcoBot, your waste-sorting tutor. Ask me anything about recycling, composting, or how to sort your waste correctly!",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
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

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isAiResponding) return;

    setState(() {
      _messages.add(_ChatBubble(
        text: trimmed,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isAiResponding = true;
    });
    _textController.clear();
    _scrollToBottom();

    final buffer = StringBuffer();

    await for (final chunk in _chatService.sendMessage(trimmed)) {
      buffer.write(chunk);
      setState(() {
        // Remove typing indicator if present, update last AI bubble
        final existingIdx = _messages.lastIndexWhere(
          (m) => !m.isUser && m.isStreaming,
        );
        if (existingIdx != -1) {
          _messages[existingIdx] = _ChatBubble(
            text: buffer.toString(),
            isUser: false,
            timestamp: DateTime.now(),
            isStreaming: true,
          );
        } else {
          _messages.add(_ChatBubble(
            text: buffer.toString(),
            isUser: false,
            timestamp: DateTime.now(),
            isStreaming: true,
          ));
        }
      });
      _scrollToBottom();
    }

    // Finalise the bubble
    setState(() {
      final idx = _messages.lastIndexWhere(
        (m) => !m.isUser && m.isStreaming,
      );
      if (idx != -1) {
        _messages[idx] = _ChatBubble(
          text: buffer.toString(),
          isUser: false,
          timestamp: DateTime.now(),
          isStreaming: false,
        );
      }
      _isAiResponding = false;
    });
    _scrollToBottom();

    if (_ttsEnabled && buffer.isNotEmpty) {
      await _tts.speak(buffer.toString());
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FAF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.eco, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EcoBot',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Waste-sorting tutor',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _ttsEnabled ? Icons.volume_up : Icons.volume_off,
              color: Colors.white70,
              size: 22,
            ),
            tooltip: 'Toggle text-to-speech',
            onPressed: () {
              setState(() => _ttsEnabled = !_ttsEnabled);
              if (!_ttsEnabled) _tts.stop();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 22),
            tooltip: 'Clear chat',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear chat?'),
                  content: const Text('This will delete all messages in this conversation.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _messages.clear();
                          _chatService.clearHistory();
                          _addWelcomeMessage();
                        });
                      },
                      child: const Text('Clear', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(16),
                vertical: getProportionateScreenHeight(12),
              ),
              itemCount: _messages.length + (_isAiResponding && _messages.last.isUser ? 1 : 0),
              itemBuilder: (context, index) {
                // Typing indicator
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg, index);
              },
            ),
          ),

          // Quick prompts (scrollable horizontal)
          if (!_isAiResponding)
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return ActionChip(
                    label: Text(
                      _quickPrompts[i],
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.green.shade300),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                    onPressed: () => _send(_quickPrompts[i]),
                  );
                },
              ),
            ),

          const SizedBox(height: 6),

          // Input bar
          Container(
            padding: EdgeInsets.only(
              left: getProportionateScreenWidth(12),
              right: getProportionateScreenWidth(8),
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    maxLines: null,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Ask EcoBot about waste sorting...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.teal.shade600],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isAiResponding
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isAiResponding ? null : () => _send(_textController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatBubble msg, int index) {
    final isUser = msg.isUser;
    final isLast = index == _messages.length - 1;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: getProportionateScreenHeight(10),
          left: isUser ? getProportionateScreenWidth(48) : 0,
          right: isUser ? 0 : getProportionateScreenWidth(48),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUser)
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.eco, size: 18, color: Colors.green.shade700),
                ),
              ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xFF2E7D32) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(msg.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser
                                ? Colors.white.withOpacity(0.6)
                                : Colors.grey.shade400,
                          ),
                        ),
                        if (msg.isStreaming && !isUser) ...[
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.green.shade400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isUser)
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 18, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.eco, size: 18, color: Colors.green.shade700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _dotsController,
              builder: (_, __) {
                final dots = '.'.characters
                    .take((_dotsController.value * 3).floor() + 1)
                    .toString();
                return Text(
                  'EcoBot is thinking$dots',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  _ChatBubble({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });
}
