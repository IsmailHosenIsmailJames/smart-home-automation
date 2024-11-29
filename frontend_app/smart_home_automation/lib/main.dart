import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_home_automation/firebase_options.dart';
import 'package:smart_home_automation/src/screens/auth/login/login_page.dart';
import 'package:smart_home_automation/src/screens/home/home_page.dart';
import 'package:smart_home_automation/src/theme/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox("info");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      defaultTransition: Transition.leftToRight,
      theme: ThemeData(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade900,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            backgroundColor: AppColors().primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      home: Hive.box('info').get("userInfo") != null
          ? const HomePage()
          : const LoginPage(),
    );
  }
}
