import 'package:deep_waste/constants/app_properties.dart';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/User.dart';
import 'package:deep_waste/screens/MainNavigationScreen.dart';
import 'package:deep_waste/screens/OnboardingScreen.dart';
import 'package:deep_waste/screens/UserScreen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  static String routeName = "/splash_screen";

  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> opacity;

  User? user;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _initApp();

    controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    opacity = Tween<double>(begin: 1.0, end: 0.0).animate(controller)
      ..addListener(() {
        if (mounted) setState(() {});
      });

    controller.forward().then((_) {
      _afterSplash();
    });
  }

  Future<void> _initApp() async {
    setState(() => isLoading = true);

    user = await DatabaseManager.instance.getUser();

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  /// Called after splash animation finishes.
  /// Shows permission popup, then navigates.
  Future<void> _afterSplash() async {
    if (!mounted) return;

    // Show permission popup
    await _showPermissionPopup();

    // Navigate to the right screen
    navigationPage();
  }

  /// Shows a custom popup explaining why we need permissions,
  /// then requests them via the system dialogs.
  Future<void> _showPermissionPopup() async {
    // Check if already shown before
    final prefs = await SharedPreferences.getInstance();
    final permissionsShown = prefs.getBool('permissions_shown') ?? false;
    if (permissionsShown) return;

    // Check if already granted
    final cam = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    final loc = await Permission.locationWhenInUse.status;

    if (cam.isGranted && mic.isGranted && loc.isGranted) {
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 40,
                  color: Color(0xFF0D9488),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enable Features',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Eco-Giants needs a few permissions to work properly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              _buildPermRow(Icons.camera_alt, 'Camera', 'Classify waste with photos'),
              const SizedBox(height: 8),
              _buildPermRow(Icons.mic, 'Microphone', 'Talk to the AI tutor'),
              const SizedBox(height: 8),
              _buildPermRow(Icons.location_on, 'Location', 'Find nearby bins'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != true) return;

    // Mark as shown so we don't prompt again
    await prefs.setBool('permissions_shown', true);

    // Request all three permissions — iOS will show native prompts one by one
    await [
      Permission.camera,
      Permission.microphone,
      Permission.locationWhenInUse,
    ].request();
  }

  Widget _buildPermRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D9488).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF0D9488)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> navigationPage() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    final loggedIn = prefs.getBool('logged_in') ?? false;

    late final Widget nextPage;
    if (!onboardingComplete) {
      nextPage = const OnboardingScreen();
    } else if (loggedIn || user != null) {
      nextPage = const MainNavigationScreen();
    } else {
      nextPage = const UserScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(color: transparentGreen),
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: <Widget>[
                Expanded(
                  child: Opacity(
                    opacity: opacity.value,
                    child: Image.asset('assets/images/logo.png'),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(text: 'Powered by '),
                        TextSpan(
                          text: 'ZOU',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
