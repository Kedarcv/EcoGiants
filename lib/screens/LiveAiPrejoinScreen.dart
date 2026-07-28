import 'dart:async';
import 'package:camera/camera.dart';
import 'package:deep_waste/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'LiveAiScreen.dart';

/// Prejoin Screen — Camera preview + mic check before entering the Live AI room.
///
/// Pattern: livekit_components Prejoin widget.
/// The student sees themselves, confirms camera/mic, then taps "Join EcoBot Room"
/// which auto-generates a JWT and connects to LiveKit Cloud.
class LiveAiPrejoinScreen extends StatefulWidget {
  static const String routeName = '/live_ai_prejoin';

  const LiveAiPrejoinScreen({super.key});

  @override
  State<LiveAiPrejoinScreen> createState() => _LiveAiPrejoinScreenState();
}

class _LiveAiPrejoinScreenState extends State<LiveAiPrejoinScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  bool _camOn = true;
  bool _micOn = true;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final camPerm = await Permission.camera.request();
    final micPerm = await Permission.microphone.request();

    if (camPerm.isDenied || micPerm.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera and microphone permissions are required.'),
          ),
        );
      }
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    final cam = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      cam,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() => _cameraReady = true);
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _cameraController == null) return;
    final current = _cameraController!.description.lensDirection;
    final next = _cameras.firstWhere(
      (c) => c.lensDirection != current,
      orElse: () => _cameras.first,
    );
    await _cameraController!.dispose();
    _cameraController = CameraController(
      next,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _joinRoom() async {
    setState(() => _joining = true);
    HapticFeedback.mediumImpact();

    // Small delay for UX feedback
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LiveAiScreen(
          cameraOn: _camOn,
          microphoneOn: _micOn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate-900
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'EcoBot Live Session',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Camera preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_cameraReady && _cameraController != null)
                        CameraPreview(_cameraController!)
                      else
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white70),
                        ),

                      // Camera off overlay
                      if (_cameraReady && !_camOn)
                        Container(
                          color: Colors.black87,
                          child: const Center(
                            child: Icon(
                              Icons.videocam_off_outlined,
                              color: Colors.white54,
                              size: 64,
                            ),
                          ),
                        ),

                      // Flip camera button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _circleButton(
                          icon: Icons.flip_camera_ios,
                          onTap: _flipCamera,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _toggleButton(
                  icon: _micOn ? Icons.mic : Icons.mic_off,
                  label: _micOn ? 'Mic On' : 'Mic Off',
                  isOn: _micOn,
                  onTap: () => setState(() => _micOn = !_micOn),
                ),
                const SizedBox(width: 24),
                _toggleButton(
                  icon: _camOn ? Icons.videocam : Icons.videocam_off,
                  label: _camOn ? 'Cam On' : 'Cam Off',
                  isOn: _camOn,
                  onTap: () {
                    setState(() => _camOn = !_camOn);
                    if (_camOn) {
                      _cameraController?.resumePreview();
                    } else {
                      _cameraController?.pausePreview();
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Join button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _joining ? null : _joinRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _joining
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Join EcoBot Room',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'You\'ll connect to the AI tutor with camera & mic.',
              style: TextStyle(
                fontSize: getProportionateScreenWidth(12),
                color: Colors.white54,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _toggleButton({
    required IconData icon,
    required String label,
    required bool isOn,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isOn ? Colors.white : Colors.red.shade400,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isOn ? Colors.black87 : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: getProportionateScreenWidth(12),
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
