import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/User.dart';
import 'package:deep_waste/screens/MainNavigationScreen.dart';
import 'package:deep_waste/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = false;
  String? _error;

  @override
  void dispose() {
    _studentController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final studentNumber = _studentController.text.trim();
    final name = _nameController.text.trim();

    try {
      if (_isLoginMode) {
        // Login — check if student exists
        final userData = await ApiService.instance.login(studentNumber);
        if (userData != null) {
          await _saveUserLocally(userData);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            );
          }
          return;
        }
        // Not found — show error
        setState(() {
          _error = 'Student not found. Please register first.';
          _isLoading = false;
        });
      } else {
        // Register
        if (name.isEmpty) {
          setState(() {
            _error = 'Please enter your name';
            _isLoading = false;
          });
          return;
        }

        final userData = await ApiService.instance.register(studentNumber, name);
        if (userData != null) {
          await _saveUserLocally(userData);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            );
          }
          return;
        }
        setState(() {
          _error = 'Registration failed. Student number may already be taken.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserLocally(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_number', data['student_number']);
    await prefs.setString('user_name', data['name']);
    await prefs.setInt('user_id', data['id']);
    await prefs.setBool('logged_in', true);

    // Also save to local SQLite
    final user = User(
      id: data['id'],
      name: data['name'],
      totalPoints: data['total_points'] ?? 0,
      ecoLevel: data['eco_level'] ?? 'Seedling',
      currentStreak: data['current_streak'] ?? 0,
      maxStreak: data['max_streak'] ?? 0,
      onboardingComplete: true,
    );
    await DatabaseManager.instance.insertUser(user);
    await DatabaseManager.instance.updateRealUserInLeaderboard(user);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: getProportionateScreenHeight(40)),

                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: getProportionateScreenHeight(100),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  _isLoginMode ? 'Welcome Back' : 'Join Eco-Giants',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode
                      ? 'Enter your student number to continue'
                      : 'Register with your ZOU student number',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 40),

                // Student number field
                TextFormField(
                  controller: _studentController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Student Number',
                    hintText: 'e.g. H2012345K',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your student number';
                    }
                    return null;
                  },
                ),

                // Name field (only in register mode)
                if (!_isLoginMode) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. Tafara Moyo',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (val) {
                      if (!_isLoginMode && (val == null || val.trim().isEmpty)) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 8),

                // Error
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _isLoginMode ? 'Login' : 'Create Account',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Toggle login/register
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoginMode = !_isLoginMode;
                      _error = null;
                    });
                  },
                  child: Text(
                    _isLoginMode
                        ? "Don't have an account? Register"
                        : 'Already have an account? Login',
                    style: const TextStyle(color: Color(0xFF0D9488)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
