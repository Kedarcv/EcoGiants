import 'package:deep_waste/screens/DisposalHistoryScreen.dart';
import 'package:deep_waste/screens/EcoBotChatScreen.dart';
import 'package:deep_waste/screens/HomeScreen.dart';
import 'package:deep_waste/screens/LeaderboardScreen.dart';
import 'package:deep_waste/screens/LiveAiPrejoinScreen.dart';
import 'package:deep_waste/screens/LiveAiScreen.dart';
import 'package:deep_waste/screens/QRScannerScreen.dart';
import 'package:deep_waste/screens/RewardsScreen.dart';
import 'package:deep_waste/screens/SettingsScreen.dart';
import 'package:deep_waste/screens/SplashScreen.dart';
import 'package:deep_waste/screens/VerificationSuccessScreen.dart';
import 'package:flutter/widgets.dart';

// We use name route
// All our routes will be available here
final Map<String, WidgetBuilder> routes = {
  SplashScreen.routeName: (context) => const SplashScreen(),
  HomeScreen.routeName: (context) => const HomeScreen(),
  RewardsScreen.routeName: (context) => const RewardsScreen(),
  LeaderboardScreen.routeName: (context) => const LeaderboardScreen(),
  DisposalHistoryScreen.routeName: (context) => const DisposalHistoryScreen(),
  LiveAiScreen.routeName: (context) => const LiveAiScreen(),
  EcoBotChatScreen.routeName: (context) => const EcoBotChatScreen(),
  SettingsScreen.routeName: (context) {
    // SettingsScreen requires a user argument, so this route needs special handling
    // In practice, use MaterialPageRoute directly
    throw UnsupportedError('SettingsScreen requires a User argument');
  },
  QRScannerScreen.routeName: (context) {
    throw UnsupportedError('QRScannerScreen requires an expectedCategory argument');
  },
  VerificationSuccessScreen.routeName: (context) {
    throw UnsupportedError('VerificationSuccessScreen requires arguments');
  },
};
