import 'dart:async';
import 'dart:convert';
import 'package:deep_waste/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GeminiLiveService {
  WebSocketChannel? _channel;
  bool _connected = false;
  bool _connecting = false;
  String? _errorMessage;

  final StreamController<Uint8List> _audioOutputController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Uint8List> get audioOutput => _audioOutputController.stream;
  Stream<Map<String, dynamic>> get events => _eventController.stream;
  bool get isConnected => _connected;
  bool get isConnecting => _connecting;
  String? get errorMessage => _errorMessage;

  Future<void> connect({required String studentNumber}) async {
    if (_connecting) return;
    _connecting = true;
    _errorMessage = null;

    try {
      final wsUrl = ApiService.baseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');
      final uri = Uri.parse('$wsUrl/ws');

      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;
      _connected = true;
      _connecting = false;

      _channel!.stream.listen(
        (data) {
          if (data is List<int>) {
            _audioOutputController.add(Uint8List.fromList(data));
          } else if (data is String) {
            try {
              final event = jsonDecode(data) as Map<String, dynamic>;
              _eventController.add(event);
            } catch (_) {}
          }
        },
        onError: (error) {
          _errorMessage = error.toString();
          _connected = false;
          _connecting = false;
        },
        onDone: () {
          _connected = false;
          _connecting = false;
        },
        cancelOnError: false,
      );
    } catch (e) {
      _connected = false;
      _connecting = false;
      _errorMessage = e.toString();
      if (kDebugMode) print('Gemini connect error: $e');
    }
  }

  void sendAudio(Uint8List pcmData) {
    _channel?.sink.add(pcmData);
  }

  void sendVideoFrame(Uint8List jpegData) {
    final base64Str = base64Encode(jpegData);
    final message = jsonEncode({'type': 'image', 'data': base64Str});
    _channel?.sink.add(message);
  }

  void sendText(String text) {
    _channel?.sink.add(text);
  }

  Future<void> disconnect() async {
    _connected = false;
    _connecting = false;
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _audioOutputController.close();
    _eventController.close();
  }
}
