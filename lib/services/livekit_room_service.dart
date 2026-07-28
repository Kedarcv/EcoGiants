import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:deep_waste/services/livekit_config.dart';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

/// LiveKit Access Token Generator (client-side for demo)
class LiveKitTokenGenerator {
  static String _base64UrlEncode(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String generateToken({
    required String roomName,
    required String participantName,
    Duration ttl = const Duration(hours: 6),
  }) {
    final header = jsonEncode({'alg': 'HS256', 'typ': 'JWT'});
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
/// LiveKit Eco-Room Service — Real WebRTC via livekit_client
/// ────────────────────────────────────────────────────────────────
/// Wraps the official LiveKit Flutter SDK Room for:
///   • Real video/audio publishing to the cloud
///   • Subscribing to AI agent tracks (audio/video/data)
///   • Data channel for chat messages
///   • Connection quality monitoring
class LiveKitRoomService extends ChangeNotifier {
  late final Room _room;
  EventsListener<RoomEvent>? _listener;
  bool _connected = false;
  bool _connecting = false;
  String? _errorMessage;
  List<Participant> _participants = [];
  LocalParticipant? get localParticipant => _room.localParticipant;

  bool get isConnected => _connected;
  bool get isConnecting => _connecting;
  String? get errorMessage => _errorMessage;
  List<Participant> get participants => _participants;
  Room get room => _room;
  
  bool get isCameraOff {
    if (_room.localParticipant == null) return true;
    return !_room.localParticipant!.isCameraEnabled();
  }
  
  bool get isMicrophoneOff {
    if (_room.localParticipant == null) return true;
    return !_room.localParticipant!.isMicrophoneEnabled();
  }

  LiveKitRoomService() {
    _room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );
  }

  Future<void> connect({
    String? url,
    String? token,
    String roomName = 'eco-giants-tutor-room',
    String participantName = 'student',
    bool micEnabled = true,
  }) async {
    if (_connecting) return;
    _connecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final wsUrl = url ?? LiveKitConfig.wsUrl;
      final jwtToken = token ??
          LiveKitTokenGenerator.generateToken(
            roomName: roomName,
            participantName: '$participantName-${DateTime.now().millisecondsSinceEpoch}',
          );

      _listener?.dispose();
      _listener = _room.createListener();
      _setupListeners();

      await _room.connect(
        wsUrl,
        jwtToken,
        connectOptions: const ConnectOptions(
          autoSubscribe: true,
        ),
      );

      // Publish camera and mic after connected
      try {
        await _room.localParticipant?.setMicrophoneEnabled(micEnabled);
        await _room.localParticipant?.setCameraEnabled(true);
      } catch (_) {}

      _connected = true;
      _connecting = false;
      notifyListeners();
    } catch (e) {
      _connected = false;
      _connecting = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (kDebugMode) print('LiveKit connect error: $e');
    }
  }

  void _setupListeners() {
    _listener!
      ..on<RoomConnectedEvent>((_) {
        _connected = true;
        _updateParticipants();
        notifyListeners();
      })
      ..on<RoomDisconnectedEvent>((_) {
        _connected = false;
        _updateParticipants();
        notifyListeners();
      })
      ..on<ParticipantConnectedEvent>((event) {
        _updateParticipants();
        notifyListeners();
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        _updateParticipants();
        notifyListeners();
      })
      ..on<TrackSubscribedEvent>((event) {
        notifyListeners();
      })
      ..on<LocalTrackPublishedEvent>((event) {
        notifyListeners();
      })
      ..on<TrackMutedEvent>((event) {
        notifyListeners();
      })
      ..on<TrackUnmutedEvent>((event) {
        notifyListeners();
      })
      ..on<RoomRecordingStatusChanged>((event) {
        notifyListeners();
      });
  }

  void _updateParticipants() {
    _participants = [
      if (_room.localParticipant != null) _room.localParticipant!,
      ..._room.remoteParticipants.values,
    ];
  }

  Future<void> disconnect() async {
    _connected = false;
    _connecting = false;
    await _listener?.dispose();
    await _room.disconnect();
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    if (_room.localParticipant == null) return;
    final enabled = _room.localParticipant!.isCameraEnabled();
    await _room.localParticipant!.setCameraEnabled(!enabled);
    notifyListeners();
  }

  Future<void> toggleMicrophone() async {
    if (_room.localParticipant == null) return;
    final enabled = _room.localParticipant!.isMicrophoneEnabled();
    await _room.localParticipant!.setMicrophoneEnabled(!enabled);
    notifyListeners();
  }

  Future<void> switchCamera() async {
    final track = _room.localParticipant?.videoTrackPublications.firstOrNull?.track
        as LocalVideoTrack?;
    if (track == null) return;

    final devices = await Hardware.instance.videoInputs();
    if (devices.isEmpty) return;

    // Toggle between first two devices (usually front/back)
    final currentDeviceId = track.currentOptions.deviceId;
    final nextDevice = devices.firstWhere(
      (d) => d.deviceId != currentDeviceId,
      orElse: () => devices.first,
    );

    await track.switchCamera(nextDevice.deviceId);
    notifyListeners();
  }

  Future<void> sendChatMessage(String message) async {
    await _room.localParticipant?.publishData(
      utf8.encode(message),
      reliable: true,
    );
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
