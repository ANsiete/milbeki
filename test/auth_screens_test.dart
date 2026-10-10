import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/theme/app_theme.dart';
import 'package:milbeki_app/features/auth/presentation/login_screen.dart';
import 'package:milbeki_app/features/auth/presentation/register_screen.dart';

Widget _wrap(Widget screen) =>
    MaterialApp(theme: AppTheme.light(), home: screen);

void main() {
  testWidgets('Login with empty fields shows both errors', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));

    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('Login with valid input shows no field errors', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));

    await tester.enterText(find.byKey(const Key('emailField')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'secret123');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    expect(find.text('Enter your email'), findsNothing);
    expect(find.text('Enter your password'), findsNothing);
  });

  testWidgets('The eye button shows and hides the password', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));

    final field = find.descendant(
      of: find.byKey(const Key('passwordField')),
      matching: find.byType(TextField),
    );

    expect(tester.widget<TextField>(field).obscureText, isTrue);

    await tester.tap(find.byKey(const Key('togglePassword')));
    await tester.pump();

    expect(tester.widget<TextField>(field).obscureText, isFalse);
  });

  testWidgets('Register rejects mismatched passwords', (tester) async {
    await tester.pumpWidget(_wrap(const RegisterScreen()));

    await tester.enterText(find.byKey(const Key('nameField')), 'Ashraf');
    await tester.enterText(find.byKey(const Key('emailField')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'milbeki2026');
    await tester.enterText(find.byKey(const Key('confirmField')), 'different1');

    await tester.ensureVisible(find.byKey(const Key('registerButton')));
    await tester.tap(find.byKey(const Key('registerButton')));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('Valid registration reaches the welcome screen', (tester) async {
    await tester.pumpWidget(_wrap(const RegisterScreen()));

    await tester.enterText(find.byKey(const Key('nameField')), 'Ashraf');
    await tester.enterText(find.byKey(const Key('emailField')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'milbeki2026');
    await tester.enterText(find.byKey(const Key('confirmField')), 'milbeki2026');

    await tester.ensureVisible(find.byKey(const Key('registerButton')));
    await tester.tap(find.byKey(const Key('registerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Ashraf!'), findsOneWidget);
    expect(find.text("Let's Get Started"), findsOneWidget);
  });
}