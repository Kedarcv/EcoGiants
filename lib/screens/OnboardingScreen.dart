import 'package:deep_waste/constants/onboarding_contents.dart';
import 'package:deep_waste/screens/MainNavigationScreen.dart';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/screens/UserScreen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;

  int _currentPage = 0;

  final List<Color> colors = const [
    Color(0xffDAD3C8),
    Color(0xffFFE5DE),
    Color(0xffDCF6E6),
    Color(0xffE3F2FD), // 4th screen color
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  void _goToHome(BuildContext context) async {
    await _markOnboardingComplete();
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  void _goToRegister(BuildContext context) async {
    await _markOnboardingComplete();
    if (!mounted) return;

    // Show permissions screen before navigating to register
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _PermissionsScreen()),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => UserScreen()),
    );
  }

  AnimatedContainer _buildDots({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeIn,
      margin: const EdgeInsets.only(right: 5),
      height: 10,
      width: _currentPage == index ? 20 : 10,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(50)),
        color: Color(0xFF000000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    final width = SizeConfig.screenWidth;
    final height = SizeConfig.screenHeight;

    return Scaffold(
      backgroundColor: colors[_currentPage],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                itemCount: contents.length,
                onPageChanged: (value) {
                  setState(() => _currentPage = value);
                },
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Image.asset(
                          contents[i].image,
                          height: SizeConfig.blockV * 35,
                        ),
                        SizedBox(height: height >= 840 ? 60 : 30),
                        if (contents[i].title.isNotEmpty)
                          Text(
                            contents[i].title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: "Mulish",
                              fontWeight: FontWeight.w600,
                              fontSize: width <= 550 ? 30 : 35,
                            ),
                          ),
                        if (contents[i].title.isNotEmpty)
                          const SizedBox(height: 15),
                        Text(
                          contents[i].desc,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "Mulish",
                            fontWeight: FontWeight.w300,
                            fontSize: width <= 550 ? 17 : 25,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // DOTS + BUTTONS
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      contents.length,
                      (index) => _buildDots(index: index),
                    ),
                  ),

                  _currentPage == contents.length - 1
                      ? Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            children: [
                              ElevatedButton(
                                onPressed: () => _goToRegister(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  padding: width <= 550
                                      ? const EdgeInsets.symmetric(
                                          horizontal: 100,
                                          vertical: 20,
                                        )
                                      : EdgeInsets.symmetric(
                                          horizontal: width * 0.2,
                                          vertical: 25,
                                        ),
                                  textStyle: TextStyle(
                                    fontSize: width <= 550 ? 16 : 20,
                                  ),
                                ),
                                child: const Text("GET STARTED"),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => _goToHome(context),
                                child: const Text(
                                  "Skip for now",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _controller.jumpToPage(
                                    contents.length - 1,
                                  );
                                },
                                child: const Text(
                                  "SKIP",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _controller.nextPage(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    curve: Curves.easeIn,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 20,
                                  ),
                                ),
                                child: const Text("NEXT"),
                              ),
                            ],
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
}

/// Permissions onboarding screen — explains why each permission is needed,
/// requests them, and guides the user to settings if permanently denied.
class _PermissionsScreen extends StatefulWidget {
  const _PermissionsScreen();

  @override
  State<_PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<_PermissionsScreen> {
  bool _cameraGranted = false;
  bool _micGranted = false;
  bool _locationGranted = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final cam = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    final loc = await Permission.locationWhenInUse.status;
    setState(() {
      _cameraGranted = cam.isGranted;
      _micGranted = mic.isGranted;
      _locationGranted = loc.isGranted;
    });
  }

  Future<void> _requestPermissions() async {
    setState(() => _requesting = true);

    // Request all permissions directly
    final results = await [
      Permission.camera,
      Permission.microphone,
      Permission.locationWhenInUse,
    ].request();

    setState(() {
      _cameraGranted = results[Permission.camera]?.isGranted ?? false;
      _micGranted = results[Permission.microphone]?.isGranted ?? false;
      _locationGranted = results[Permission.locationWhenInUse]?.isGranted ?? false;
      _requesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 48,
                  color: Color(0xFF0D9488),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enable Features',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Eco-Giants needs a few permissions to work properly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // Permission cards
              _buildPermissionCard(
                icon: Icons.camera_alt,
                title: 'Camera',
                description: 'Classify waste by taking photos',
                granted: _cameraGranted,
              ),
              const SizedBox(height: 12),
              _buildPermissionCard(
                icon: Icons.mic,
                title: 'Microphone',
                description: 'Talk to the Eco AI tutor',
                granted: _micGranted,
              ),
              const SizedBox(height: 12),
              _buildPermissionCard(
                icon: Icons.location_on,
                title: 'Location',
                description: 'Find nearby recycling bins',
                granted: _locationGranted,
              ),

              const Spacer(),

              // Allow button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _requesting
                      ? null
                      : (_cameraGranted && _micGranted && _locationGranted)
                          ? null
                          : _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _requesting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          (_cameraGranted && _micGranted && _locationGranted)
                              ? 'All permissions granted!'
                              : 'Allow Permissions',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Skip
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text(
                  'Skip for now',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool granted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: granted
              ? const Color(0xFF10B981)
              : Colors.grey.shade200,
          width: granted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: granted
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : const Color(0xFF0D9488).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: granted ? const Color(0xFF10B981) : const Color(0xFF0D9488),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            granted ? Icons.check_circle : Icons.arrow_forward_ios,
            color: granted ? const Color(0xFF10B981) : Colors.grey.shade400,
            size: granted ? 24 : 16,
          ),
        ],
      ),
    );
  }
}
