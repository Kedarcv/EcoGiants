import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:deep_waste/services/livekit_config.dart';

/// A simple message model for chat history.
class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// Service that streams text completions from NVIDIA's hosted
/// Llama-3.1-8B-Instruct endpoint via the OpenAI-compatible API.
class NvidiaChatService {
  final List<ChatMessage> _history = [];

  /// System prompt that gives the AI its eco-tutor persona.
  static const String _systemPrompt =
      "You are EcoBot, a friendly and enthusiastic AI tutor for Eco-Giants, "
      "an educational app that teaches students how to sort waste correctly.\n\n"
      "Your job is to help students learn about:\n"
      "1. What items belong in Recyclable, Organic, E-Waste, Hazardous, and General waste bins.\n"
      "2. Why proper sorting matters for the environment.\n"
      "3. Fun facts about recycling, composting, and sustainability.\n"
      "4. Local tips (you can ask the student where they are if location-specific advice is needed).\n\n"
      "Rules:\n"
      "- Keep responses concise (1-3 short paragraphs max) so they work well with text-to-speech.\n"
      "- Use encouraging, positive language suited for students.\n"
      "- If a student shows you an item via the camera, describe what you see and tell them which bin it goes into.\n"
      "- Never give medical or legal advice. For hazardous waste, always advise consulting local authorities.\n"
      "- When unsure, say I'm not sure about that one — let's look it up together!";

  /// Send a user message and receive an SSE-style stream of text chunks.
  Stream<String> sendMessage(String userMessage) async* {
    _history.add(ChatMessage(role: 'user', content: userMessage));

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      ..._history.map((m) => m.toJson()),
    ];

    final uri = Uri.parse('${NvidiaConfig.baseUrl}/chat/completions');
    final request = http.Request('POST', uri);
    request.headers['Authorization'] = 'Bearer ${NvidiaConfig.apiKey}';
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'text/event-stream';

    request.body = jsonEncode({
      'model': NvidiaConfig.model,
      'messages': messages,
      'temperature': NvidiaConfig.temperature,
      'max_tokens': NvidiaConfig.maxTokens,
      'stream': true,
    });

    final streamedResponse = await request.send();
    final stream = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final buffer = StringBuffer();

    await for (final line in stream) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6);
        if (data == '[DONE]') break;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              buffer.write(content);
              yield content;
            }
          }
        } catch (_) {
          // Skip malformed SSE lines
        }
      }
    }

    if (buffer.isNotEmpty) {
      _history.add(
        ChatMessage(role: 'assistant', content: buffer.toString()),
      );
    }
  }

  Future<String> sendMessageSync(String userMessage) async {
    final buffer = StringBuffer();
    await for (final chunk in sendMessage(userMessage)) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  void clearHistory() => _history.clear();

  List<ChatMessage> get history => List.unmodifiable(_history);
}
