import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audio_session/audio_session.dart';
import 'package:camera/camera.dart';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/services/gemini_live_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart' hide AudioSource;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  bool _videoEnabled = false; // Default to OFF as requested
  int _selectedCameraIndex = 0;
  Timer? _videoFrameTimer;

  AgentUiState _state = AgentUiState.idle;
  bool _micEnabled = true;
  String _statusText = 'Tap the button to talk to Eco';
  String? _errorText;
  StreamSubscription<Map<String, dynamic>>? _eventSub;
  StreamSubscription<Uint8List>? _audioOutputSub;
  StreamSubscription<Uint8List>? _micSub;

  final List<int> _audioTurnBuffer = [];
  Timer? _audioFlushTimer;

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
    _audioOutputSub = _geminiService.audioOutput.listen(_onAudioOutput);
    _configureAudioSession();
    _initAudioHardware();
    _loadCameras();
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      ));
      await session.setActive(true);
    } catch (e) {
      debugPrint('AudioSession config error: $e');
    }
  }

  Future<void> _initAudioHardware() async {
    try {
      await _recorder.openRecorder();
    } catch (e) {
      debugPrint('Audio hardware init error: $e');
    }
  }

  Future<void> _loadCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _selectedCameraIndex = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;
      }
    } catch (e) {
      debugPrint('Camera load error: $e');
    }
  }

  Future<void> _toggleVideo() async {
    setState(() {
      _videoEnabled = !_videoEnabled;
    });

    if (_videoEnabled) {
      await _startCamera();
    } else {
      await _stopCamera();
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    if (_videoEnabled) {
      await _startCamera();
    }
  }

  Future<void> _startCamera() async {
    if (_cameras.isEmpty) return;
    await _stopCamera();

    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() => _videoEnabled = false);
        return;
      }

      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.low,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _cameraReady = true);
        if (_geminiService.isConnected) {
          _startVideoStream();
        }
      }
    } catch (e) {
      debugPrint('Camera start error: $e');
      if (mounted) setState(() => _videoEnabled = false);
    }
  }

  Future<void> _stopCamera() async {
    _videoFrameTimer?.cancel();
    if (_cameraController != null) {
      await _cameraController?.dispose();
      _cameraController = null;
      if (mounted) setState(() => _cameraReady = false);
    }
  }

  void _startVideoStream() {
    _videoFrameTimer?.cancel();
    if (!_videoEnabled || !_cameraReady || _cameraController == null) return;

    _videoFrameTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_cameraController != null &&
          _cameraReady &&
          _videoEnabled &&
          _geminiService.isConnected &&
          !_cameraController!.value.isTakingPicture) {
        try {
          final XFile file = await _cameraController!.takePicture();
          final bytes = await file.readAsBytes();
          _geminiService.sendVideoFrame(bytes);
          await File(file.path).delete();
        } catch (e) {
          debugPrint('Video frame send error: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _eventSub?.cancel();
    _audioOutputSub?.cancel();
    _micSub?.cancel();
    _stopCamera();
    _audioFlushTimer?.cancel();
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    _geminiService.dispose();
    super.dispose();
  }

  Uint8List _addWavHeader(Uint8List pcmBytes, int sampleRate) {
    final int totalDataLen = pcmBytes.length;
    final int totalLength = totalDataLen + 36;
    final int byteRate = sampleRate * 1 * 2;

    final builder = BytesBuilder();
    builder.add(ascii.encode('RIFF'));
    builder.add(Uint8List(4)..buffer.asByteData().setInt32(0, totalLength, Endian.little));
    builder.add(ascii.encode('WAVE'));
    builder.add(ascii.encode('fmt '));
    builder.add(Uint8List(4)..buffer.asByteData().setInt32(0, 16, Endian.little));
    builder.add(Uint8List(2)..buffer.asByteData().setInt16(0, 1, Endian.little));
    builder.add(Uint8List(2)..buffer.asByteData().setInt16(0, 1, Endian.little));
    builder.add(Uint8List(4)..buffer.asByteData().setInt32(0, sampleRate, Endian.little));
    builder.add(Uint8List(4)..buffer.asByteData().setInt32(0, byteRate, Endian.little));
    builder.add(Uint8List(2)..buffer.asByteData().setInt16(0, 2, Endian.little));
    builder.add(Uint8List(2)..buffer.asByteData().setInt16(0, 16, Endian.little));
    builder.add(ascii.encode('data'));
    builder.add(Uint8List(4)..buffer.asByteData().setInt32(0, totalDataLen, Endian.little));
    builder.add(pcmBytes);
    return builder.toBytes();
  }

  Future<void> _onAudioOutput(Uint8List pcmData) async {
    _audioTurnBuffer.addAll(pcmData);

    _audioFlushTimer?.cancel();
    _audioFlushTimer = Timer(const Duration(milliseconds: 250), () {
      _flushAudioBuffer();
    });
  }

  Future<void> _flushAudioBuffer() async {
    if (_audioTurnBuffer.isEmpty) return;
    try {
      final fullPcm = Uint8List.fromList(List<int>.from(_audioTurnBuffer));
      _audioTurnBuffer.clear();
      final wavData = _addWavHeader(fullPcm, 24000);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/eco_${DateTime.now().millisecondsSinceEpoch}.wav');
      await file.writeAsBytes(wavData);
      await _audioPlayer.setAudioSource(AudioSource.file(file.path));
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  void _onEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    final type = event['type'] as String?;
    setState(() {
      if (type == 'ready') {
        _state = AgentUiState.agentSpeaking;
        _statusText = 'Eco is online! Greeting you…';
        _startMicStream();
        if (_videoEnabled) _startVideoStream();
        Future.delayed(const Duration(milliseconds: 300), () {
          _geminiService.sendText('Hello Eco, introduce yourself in English as the AI tutor for ZOU students!');
        });
      } else if (type == 'user') {
        _statusText = 'You: ${event['text']}';
      } else if (type == 'gemini') {
        _state = AgentUiState.agentSpeaking;
        _statusText = 'Eco: ${event['text']}';
      } else if (type == 'turn_complete') {
        _flushAudioBuffer();
        _state = AgentUiState.listening;
      } else if (type == 'interrupted') {
        _audioTurnBuffer.clear();
        _audioFlushTimer?.cancel();
        _audioPlayer.stop();
        _state = AgentUiState.listening;
      } else if (type == 'error') {
        _state = AgentUiState.error;
        _errorText = event['error'] as String?;
      }
    });
  }

  Future<void> _startMicStream() async {
    if (!_micEnabled || !_recorder.isStopped) return;
    try {
      final recordingStreamController = StreamController<Uint8List>();
      _micSub = recordingStreamController.stream.listen((pcmData) {
        if (pcmData.isNotEmpty &&
            _micEnabled &&
            _geminiService.isConnected &&
            _state == AgentUiState.listening) {
          _geminiService.sendAudio(pcmData);
        }
      });

      await _recorder.startRecorder(
        toStream: recordingStreamController.sink,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 16000,
      );
    } catch (e) {
      debugPrint('Mic stream error: $e');
    }
  }

  Future<void> _stopMicStream() async {
    try {
      _micSub?.cancel();
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }
    } catch (e) {
      debugPrint('Stop mic error: $e');
    }
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
      _statusText = 'Connecting directly to Gemini Live…';
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

      await _geminiService.connect(studentNumber: studentNumber);

      if (_geminiService.isConnected) {
        setState(() {
          _state = AgentUiState.listening;
          _micEnabled = widget.microphoneOn;
          _statusText = 'Eco is online! Say hello.';
        });
        _startMicStream();
        if (_videoEnabled) _startVideoStream();
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
    if (_micEnabled) {
      _startMicStream();
    } else {
      _stopMicStream();
    }
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
    await _stopMicStream();
    await _stopCamera();
    await _audioPlayer.stop();
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
      body: Stack(
        children: [
          // Fullscreen Camera Preview or Solid Background
          if (_videoEnabled && _cameraReady && _cameraController != null) ...[
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            ),
            // Semi-transparent dark overlay for text contrast
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ],

          // Foreground UI Content
          SafeArea(
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Text(
                            _statusText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _errorText!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
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
        ],
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
              'Eco — AI Tutor',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_cameras.length > 1) ...[
            IconButton(
              icon: const Icon(Icons.cameraswitch, color: Colors.white),
              tooltip: 'Switch Camera',
              onPressed: _switchCamera,
            ),
          ],
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
        width: speaking ? 150 : 120,
        height: speaking ? 150 : 120,
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
                color: const Color(0xFF14B8A6).withOpacity(0.6),
                blurRadius: 36,
                spreadRadius: 6,
              )
            else
              BoxShadow(
                color: const Color(0xFF0D9488).withOpacity(0.4),
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
          ? Row(
              children: [
                Expanded(
                  child: SizedBox(
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
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _videoEnabled
                        ? const Color(0xFF0D9488)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0D9488),
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    onPressed: _toggleVideo,
                    icon: Icon(
                      _videoEnabled ? Icons.videocam : Icons.videocam_off,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mic Toggle
                Container(
                  width: 60,
                  height: 60,
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
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Video Toggle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _videoEnabled
                        ? const Color(0xFF0D9488)
                        : const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0D9488),
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    onPressed: _toggleVideo,
                    icon: Icon(
                      _videoEnabled ? Icons.videocam : Icons.videocam_off,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Disconnect / Call End
                Container(
                  width: 60,
                  height: 60,
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
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
