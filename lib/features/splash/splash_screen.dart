import 'dart:async';

import 'package:flutter/material.dart';
import 'package:milbeki_app/features/auth/presentation/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.delay = const Duration(seconds: 2)});

  /// How long the splash stays on screen.
  final Duration delay;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  // initState runs once, when the screen is first created.
  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, _goToLogin);
  }

  void _goToLogin() {
    // If the screen is already gone, do nothing.
    if (!mounted) return;
    // pushReplacement swaps the splash for login, so "back" never returns to it.
    // Later (Phase 6) this will check for a saved login first.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
            ],
          ),
        ),
      ),
    );
  }
}