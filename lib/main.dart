import 'package:flutter/material.dart';
import 'package:milbeki_app/core/theme/app_theme.dart';
import 'features/practice/component_gallery_screen.dart';
import 'features/practice/expense_practice_screen.dart';

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

// The first screen the user sees.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colors.onPrimary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 52,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'MilbeKi',
                style: TextStyle(
                  color: colors.onPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'এইমাসেও হিসাব মিলবে না',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.85),
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.onPrimary,
                  foregroundColor: colors.primary,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExpensePracticeScreen(),
                    ),
                  );
                },
                child: const Text('Practice screen'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.onPrimary,
                  foregroundColor: colors.primary,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ComponentGalleryScreen(),
                    ),
                  );
                },
                child: const Text('Component gallery'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}