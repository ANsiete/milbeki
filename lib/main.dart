import 'package:flutter/material.dart';
import 'package:milbeki_app/core/theme/app_theme.dart';
import 'package:milbeki_app/features/splash/splash_screen.dart';

void main() {
  runApp(const MilbeKiApp());
}

// The root widget: it sets up the app's name, theme, and first screen.
class MilbeKiApp extends StatelessWidget {
  const MilbeKiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MilbeKi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}