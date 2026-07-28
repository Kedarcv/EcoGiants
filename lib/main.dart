import 'package:deep_waste/controller/category_notifier.dart';
import 'package:deep_waste/controller/item_notifier.dart';
import 'package:deep_waste/controller/reward_notifier.dart';
import 'package:deep_waste/controller/tips_notifier.dart';
import 'package:deep_waste/controller/user_notifier.dart';
import 'package:provider/provider.dart';
import 'package:deep_waste/routes.dart';
import 'package:deep_waste/screens/SplashScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CategoryNotifier()),
          ChangeNotifierProvider(create: (_) => ItemNotifier()),
          ChangeNotifierProvider(create: (_) => RewardNotifier()),
          ChangeNotifierProvider(create: (_) => UserNotifier()),
          ChangeNotifierProvider(create: (_) => TipsNotifier()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Eco-Giants',
          theme: ThemeData(
            appBarTheme: AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: "Mulish",
                )),
            brightness: Brightness.light,
            canvasColor: Colors.transparent,
            primarySwatch: Colors.teal,
            fontFamily: "Mulish",
            useMaterial3: true,
          ),
          builder: EasyLoading.init(),
          initialRoute: SplashScreen.routeName,
          routes: routes,
        ));
  }
}
