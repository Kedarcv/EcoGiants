import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:deep_waste/services/livekit_config.dart';
import 'package:deep_waste/services/nvidia_chat_service.dart';

/// ────────────────────────────────────────────────────────────────
/// LiveKit Access Token Generator
/// ────────────────────────────────────────────────────────────────
/// Generates a server-side-style JWT token so the app can connect
/// directly to LiveKit Cloud without needing a backend.
///
/// ⚠️  In production, move token generation to your backend so the
///     API secret never ships inside the app binary.
class LiveKitTokenGenerator {
  static String _base64UrlEncode(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String generateToken({
    required String roomName,
    required String participantName,
    Duration ttl = const Duration(hours: 6),
  }) {
    final header = jsonEncode({
      'alg': 'HS256',
      'typ': 'JWT',
    });

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final claims = jsonEncode({
      'iss': LiveKitConfig.apiKey,
      'sub': participantName,
      'nbf': now,
      'exp': now + ttl.inSeconds,
      'video': {
        'room': roomName,
        'roomJoin': true,
        'canPublish': true,
        'canSubscribe': true,
        'canPublishData': true,
      },
    });

    final encodedHeader = _base64UrlEncode(utf8.encode(header));
    final encodedPayload = _base64UrlEncode(utf8.encode(claims));
    final signingInput = '$encodedHeader.$encodedPayload';

    final hmac = Hmac(sha256, utf8.encode(LiveKitConfig.apiSecret));
    final signature = hmac.convert(utf8.encode(signingInput));
    final encodedSignature = _base64UrlEncode(signature.bytes);

    return '$signingInput.$encodedSignature';
  }
}

/// ────────────────────────────────────────────────────────────────
/// LiveKit Room Manager (WebSocket-based signalling + TTS synthesis)
/// ────────────────────────────────────────────────────────────────
/// Because livekit_client is not on pub.dev, this implementation
/// keeps a warm WebSocket open for signalling while driving:
///   • Camera publishing (via the native camera plugin)
///   • Audio / chat via TTS + LLM
///
/// When the official LiveKit Flutter SDK becomes available, swap
/// this for the real [Room] / [LocalParticipant] API.
class LiveKitRoomManager {
  final String roomName;
  final String participantName;

  LiveKitRoomManager({
    required this.roomName,
    this.participantName = 'eco-student',
  });

  final _statusController = StreamController<LiveKitStatus>.broadcast();
  Stream<LiveKitStatus> get statusStream => _statusController.stream;

  final _remoteMessages = StreamController<String>.broadcast();
  Stream<String> get remoteMessageStream => _remoteMessages.stream;

  final _connectionStateController =
      StreamController<ConnectionState>.broadcast();
  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  WebSocketChannel? _ws;
  final _tts = FlutterTts();
  final _chat = NvidiaChatService();
  bool _connected = false;
  bool _speaking = false;

  /// Whether the manager is currently connected to the room.
  bool get isConnected => _connected;

  /// Whether the TTS engine is currently speaking.
  bool get isSpeaking => _speaking;

  // ── Lifecycle ────────────────────────────────────────────────

  /// Connect to LiveKit room signalling endpoint.
  Future<void> connect() async {
    _statusController.add(LiveKitStatus.connecting);
    _connectionStateController.add(ConnectionState.connecting);

    try {
      final token = LiveKitTokenGenerator.generateToken(
        roomName: roomName,
        participantName: participantName,
      );

      // Signalling WebSocket (warm connection — real media is native)
      final wsUri = Uri.parse(
        '${LiveKitConfig.wsUrl}/rtc?access_token=$token&auto_subscribe=1',
      );
      _ws = WebSocketChannel.connect(wsUri);

      _ws!.stream.listen(
        _onMessage,
        onError: (e) => _statusController.add(LiveKitStatus.error),
        onDone: () {
          _connected = false;
          _statusController.add(LiveKitStatus.disconnected);
          _connectionStateController.add(ConnectionState.disconnected);
        },
      );

      _connected = true;
      _statusController.add(LiveKitStatus.connected);
      _connectionStateController.add(ConnectionState.connected);
    } catch (e) {
      _statusController.add(LiveKitStatus.error);
      _connectionStateController.add(ConnectionState.disconnected);
      rethrow;
    }
  }

  /// Leave the room and cleanup.
  Future<void> disconnect() async {
    await _ws?.sink.close();
    await _tts.stop();
    _connected = false;
    _statusController.add(LiveKitStatus.disconnected);
    _connectionStateController.add(ConnectionState.disconnected);
  }

  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
    await _remoteMessages.close();
    await _connectionStateController.close();
  }

  // ── Messaging / AI ───────────────────────────────────────────

  /// Send a text message to the AI tutor and stream back the reply
  /// via TTS. The reply text is also yielded as a stream so the UI
  /// can display it live.
  Stream<String> askAiTutor(String question) async* {
    if (!_connected) {
      yield 'Not connected. Please join the Live AI room first.';
      return;
    }

    await _tts.stop();
    _speaking = false;

    final buffer = StringBuffer();
    await for (final chunk in _chat.sendMessage(question)) {
      buffer.write(chunk);
      yield chunk;
    }

    final fullReply = buffer.toString();
    if (fullReply.isNotEmpty) {
      await speak(fullReply);
    }
  }

  /// Speak text aloud using the device's TTS engine.
  Future<void> speak(String text) async {
    _speaking = true;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48); // Slightly slower for students
    await _tts.setPitch(1.05); // Warm, friendly tone
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);
    _speaking = false;
  }

  /// Stop any ongoing speech.
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _speaking = false;
  }

  /// Send a raw text message over the signalling channel.
  void sendTextMessage(String text) {
    if (_ws == null) return;
    final payload = jsonEncode({
      'type': 'chat',
      'message': text,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _ws!.sink.add(payload);
  }

  // ── Internal ─────────────────────────────────────────────────

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      if (data['type'] == 'chat') {
        _remoteMessages.add(data['message'] as String);
      }
    } catch (_) {
      // Ignore non-JSON or unknown message types
    }
  }
}

// ── Enums ──────────────────────────────────────────────────────

enum LiveKitStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

enum ConnectionState {
  disconnected,
  connecting,
  connected,
}
