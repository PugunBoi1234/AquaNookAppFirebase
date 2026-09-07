import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/phone_container_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AquaNookApp());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class AquaNookApp extends StatelessWidget {
  const AquaNookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaNook',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0B3B42),
        primaryColor: const Color(0xFF146873),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF146873),
          primary: const Color(0xFF146873),
          secondary: const Color(0xFFFF8A5B),
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const PhoneContainerWrapper(),
    );
  }
}
