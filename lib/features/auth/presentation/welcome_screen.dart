import 'package:flutter/material.dart';
import 'package:milbeki_app/features/shell/main_shell.dart';

// Shown after registration. The setup wizard is added before the shell later in Phase 3.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.celebration_outlined,
                  size: 44,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome, $displayName!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'MilbeKi will help you manage your monthly income, expenses, '
                'budgets, and the money you owe or are owed.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  key: const Key('getStartedButton'),
                  onPressed: () {
                    // Replace everything on the back stack with the main app,
                    // so "back" cannot return to Welcome or Register.
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainShell()),
                      (route) => false,
                    );
                  },
                  child: const Text("Let's Get Started"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}