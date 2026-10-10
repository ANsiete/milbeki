import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/theme/app_theme.dart';
import 'package:milbeki_app/features/auth/presentation/welcome_screen.dart';
import 'package:milbeki_app/features/shell/main_shell.dart';

Widget _app(Widget home) => MaterialApp(theme: AppTheme.light(), home: home);

void main() {
  testWidgets('Starts on Home and switches between tabs', (tester) async {
    await tester.pumpWidget(_app(const MainShell()));

    expect(find.text('Your dashboard will appear here.'), findsOneWidget);

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Your financial calendar will appear here.'), findsOneWidget);
    expect(find.text('Your dashboard will appear here.'), findsNothing);

    await tester.tap(find.text('Money Owed'));
    await tester.pumpAndSettle();
    expect(
      find.text('Money you owe and are owed will appear here.'),
      findsOneWidget,
    );

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(
      find.text('Analytics, accounts and settings will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets('Add opens the sheet with four choices and keeps the tab', (tester) async {
    await tester.pumpWidget(_app(const MainShell()));

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.text('Add Income'), findsOneWidget);
    expect(find.text('Add Money Owed'), findsOneWidget);
    expect(find.text('Add Recurring Expense'), findsOneWidget);

    await tester.tap(find.text('Add Expense'));
    await tester.pumpAndSettle();

    // The sheet is closed, a message appears, and we are still on Home.
    expect(find.text('Add Income'), findsNothing);
    expect(find.text('Add Expense is built in a later step.'), findsOneWidget);
    expect(find.text('Your dashboard will appear here.'), findsOneWidget);
  });

  testWidgets("Let's Get Started opens the main app", (tester) async {
    await tester.pumpWidget(_app(const WelcomeScreen(displayName: 'Ashraf')));

    await tester.tap(find.byKey(const Key('getStartedButton')));
    await tester.pumpAndSettle();

    expect(find.text('Your dashboard will appear here.'), findsOneWidget);
    expect(find.text('Welcome, Ashraf!'), findsNothing);
  });
}