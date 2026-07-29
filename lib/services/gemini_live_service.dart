import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:gemini_live/src/live_service.dart';
import 'gemini_config.dart';

class GeminiLiveService {
  LiveService? _liveService;
  LiveSession? _session;
  bool _connected = false;

  final StreamController<Uint8List> _audioOutputController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Uint8List> get audioOutput => _audioOutputController.stream;
  Stream<Map<String, dynamic>> get events => _eventController.stream;
  bool get isConnected => _connected;

  Future<void> connect({required String studentNumber}) async {
    try {
      if (kDebugMode) print('Connecting to v1alpha Gemini Live API...');
      _liveService = LiveService(
        apiKey: GeminiConfig.apiKey,
        apiVersion: 'v1alpha',
      );

      final params = LiveConnectParameters(
        model: GeminiConfig.model,
        config: GenerationConfig(
          responseModalities: [Modality.AUDIO],
        ),
        systemInstruction: Content(
          parts: [
            Part(
              text:
                  'You are Eco-Giant AI Tutor, a friendly sustainability and waste sorting assistant for Zimbabwe Open University (ZOU) students. ALWAYS communicate in clear, natural English. Keep responses concise, clear, and engaging.',
            ),
          ],
        ),
        callbacks: LiveCallbacks(
          onOpen: () {
            if (kDebugMode) print('Gemini Live WS Connected!');
            _connected = true;
            _eventController.add({'type': 'ready'});
          },
          onMessage: (message) {
            _handleServerMessage(message);
          },
          onError: (error, stackTrace) {
            if (kDebugMode) print('Gemini Live WS Error: $error');
            _connected = false;
            _eventController.add({'type': 'error', 'error': error.toString()});
          },
          onClose: (code, reason) {
            if (kDebugMode) print('Gemini Live WS Closed: $code / $reason');
            _connected = false;
            _eventController.add({'type': 'disconnected'});
          },
        ),
      );

      _session = await _liveService!.connect(params);
      _connected = true;
    } catch (e) {
      _connected = false;
      if (kDebugMode) print('Gemini connect error: $e');
      rethrow;
    }
  }

  void _handleServerMessage(LiveServerMessage message) {
    try {
      final content = message.serverContent;
      if (content != null) {
        if (content.outputTranscription?.text != null &&
            content.outputTranscription!.text!.isNotEmpty) {
          _eventController.add({
            'type': 'gemini',
            'text': content.outputTranscription!.text,
          });
        }

        final modelTurn = content.modelTurn;
        if (modelTurn != null && modelTurn.parts != null) {
          for (final part in modelTurn.parts!) {
            final inlineData = part.inlineData;
            if (inlineData != null && inlineData.data.isNotEmpty) {
              final audioBytes = base64Decode(inlineData.data);
              _audioOutputController.add(audioBytes);
              _eventController.add({'type': 'gemini', 'text': 'Eco is speaking…'});
            }

            if (part.text != null && part.text!.isNotEmpty) {
              _eventController.add({'type': 'gemini', 'text': part.text});
            }
          }
        }

        if (content.turnComplete == true) {
          _eventController.add({'type': 'turn_complete'});
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error handling Gemini server message: $e');
    }
  }

  void sendAudio(Uint8List pcmData) {
    if (_connected && _session != null) {
      _session!.sendAudio(pcmData);
    }
  }

  void sendVideoFrame(Uint8List jpegBytes) {
    if (_connected && _session != null) {
      final base64Video = base64Encode(jpegBytes);
      final message = LiveClientMessage(
        realtimeInput: LiveClientRealtimeInput(
          video: Blob(mimeType: 'image/jpeg', data: base64Video),
        ),
      );
      _session!.sendMessage(message);
    }
  }

  void sendText(String text) {
    if (_connected && _session != null) {
      _session!.sendText(text);
      _eventController.add({'type': 'user', 'text': text});
    }
  }

  Future<void> disconnect() async {
    _connected = false;
    await _session?.close();
    _session = null;
  }

  void dispose() {
    disconnect();
    _audioOutputController.close();
    _eventController.close();
  }
}
