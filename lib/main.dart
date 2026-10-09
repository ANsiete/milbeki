   import 'features/practice/expense_practice_screen.dart';
import 'package:flutter/material.dart';

// Every Flutter app starts at main(). runApp() puts our first widget on screen.
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
      debugShowCheckedModeBanner: false, // hides the red "DEBUG" ribbon
      theme: ThemeData(
        // Builds a whole color palette from one starting color (teal).
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// The first screen the user sees.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme.of(context) reads the theme we defined above.
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.primary,
      body: SafeArea(
        // SafeArea keeps content clear of the status bar and camera cutout.
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // A simple original brand mark: a wallet icon on a rounded square.
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
              const SizedBox(height: 24), // an empty gap
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
                  // Navigator keeps a stack of screens; push puts a new one on top.
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExpensePracticeScreen(),
                    ),
                  );
                },
                child: const Text('Practice screen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}