import 'package:deep_waste/components/default_button.dart';
import 'package:deep_waste/components/form_error.dart';
import 'package:deep_waste/constants/app_properties.dart';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/User.dart';
import 'package:deep_waste/screens/HomeScreen.dart';
import 'package:flutter/material.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _formKey = GlobalKey<FormState>();

  String? name;
  final List<String> errors = [];

  void addError({required String error}) {
    if (!errors.contains(error)) {
      setState(() {
        errors.add(error);
      });
    }
  }

  void removeError({required String error}) {
    if (errors.contains(error)) {
      setState(() {
        errors.remove(error);
      });
    }
  }

  Future<void> addUser() async {
    final user = User(
      id: 1001,
      name: name ?? 'User',
      totalPoints: 0,
      ecoLevel: 'Seedling',
      currentStreak: 0,
      maxStreak: 0,
      onboardingComplete: true,
    );

    await DatabaseManager.instance.insertUser(user);
    await DatabaseManager.instance.updateRealUserInLeaderboard(user);
  }

  Future<void> validateAndSave() async {
    final form = _formKey.currentState;

    if (form != null && form.validate()) {
      form.save();
      await addUser();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      debugPrint('Form is invalid');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(height: getProportionateScreenHeight(75)),
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    height: getProportionateScreenHeight(120),
                  ),
                  SizedBox(height: getProportionateScreenHeight(25)),
                  Text(
                    "Welcome to Eco-Giants",
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(24),
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: getProportionateScreenHeight(8)),
                  Text(
                    "Create a username to track your eco journey",
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(16),
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: getProportionateScreenHeight(30)),
                  buildUserName(),
                  FormError(errors: errors),
                  SizedBox(height: getProportionateScreenHeight(20)),
                  DefaultButton(
                    text: "Get Started",
                    press: validateAndSave,
                  ),
                  SizedBox(height: getProportionateScreenHeight(20)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextFormField buildUserName() {
    return TextFormField(
      keyboardType: TextInputType.text,
      onSaved: (newValue) => name = newValue,
      onChanged: (value) {
        name = value;

        if (value.isNotEmpty) {
          removeError(error: kItemName);
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          addError(error: kItemName);
          return "";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: "Your Name",
        hintText: "Enter your name",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }
}
