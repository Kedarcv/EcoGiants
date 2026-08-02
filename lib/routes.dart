import 'package:deep_waste/screens/DisposalHistoryScreen.dart';
import 'package:deep_waste/screens/EcoBotChatScreen.dart';
import 'package:deep_waste/screens/EnergyDetailsScreen.dart';
import 'package:deep_waste/screens/HomeScreen.dart';
import 'package:deep_waste/screens/LeaderboardScreen.dart';
import 'package:deep_waste/screens/LearningScreen.dart';
import 'package:deep_waste/screens/LiveAiScreen.dart';
import 'package:deep_waste/screens/MainNavigationScreen.dart';
import 'package:deep_waste/screens/QRCodeGeneratorScreen.dart';
import 'package:deep_waste/screens/QRScannerScreen.dart';
import 'package:deep_waste/screens/RewardsScreen.dart';
import 'package:deep_waste/screens/SettingsScreen.dart';
import 'package:deep_waste/screens/SplashScreen.dart';
import 'package:deep_waste/screens/SustainabilityAnalyticsScreen.dart';
import 'package:deep_waste/screens/VerificationSuccessScreen.dart';
import 'package:deep_waste/screens/WasteDetailsScreen.dart';
import 'package:deep_waste/screens/WaterDetailsScreen.dart';
import 'package:deep_waste/screens/WaterLeakReportScreen.dart';
import 'package:flutter/widgets.dart';

final Map<String, WidgetBuilder> routes = {
  SplashScreen.routeName: (context) => const SplashScreen(),
  MainNavigationScreen.routeName: (context) => const MainNavigationScreen(),
  HomeScreen.routeName: (context) => const HomeScreen(),
  LearningScreen.routeName: (context) => const LearningScreen(),
  RewardsScreen.routeName: (context) => const RewardsScreen(),
  LeaderboardScreen.routeName: (context) => const LeaderboardScreen(),
  DisposalHistoryScreen.routeName: (context) => const DisposalHistoryScreen(),
  LiveAiScreen.routeName: (context) => const LiveAiScreen(),
  EcoBotChatScreen.routeName: (context) => const EcoBotChatScreen(),
  QRCodeGeneratorScreen.routeName: (context) => const QRCodeGeneratorScreen(),
  SustainabilityAnalyticsScreen.routeName: (context) => const SustainabilityAnalyticsScreen(),
  WaterLeakReportScreen.routeName: (context) => const WaterLeakReportScreen(),
  WaterDetailsScreen.routeName: (context) => const WaterDetailsScreen(),
  EnergyDetailsScreen.routeName: (context) => const EnergyDetailsScreen(),
  WasteDetailsScreen.routeName: (context) => const WasteDetailsScreen(),
  SettingsScreen.routeName: (context) {
    throw UnsupportedError('SettingsScreen requires a User argument');
  },
  QRScannerScreen.routeName: (context) {
    throw UnsupportedError('QRScannerScreen requires an expectedCategory argument');
  },
  VerificationSuccessScreen.routeName: (context) {
    throw UnsupportedError('VerificationSuccessScreen requires arguments');
  },
};
