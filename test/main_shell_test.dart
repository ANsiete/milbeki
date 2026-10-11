import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/theme/app_theme.dart';
import 'package:milbeki_app/features/auth/presentation/welcome_screen.dart';
import 'package:milbeki_app/features/shell/main_shell.dart';

Widget _app(Widget home) => MaterialApp(theme: AppTheme.light(), home: home);

// A tall virtual screen, so nothing is scrolled out of view during the test.
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// Taps a bottom-bar item, looking only inside the NavigationBar.
Future<void> _tapNav(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

int _selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  testWidgets('Starts on Home and switches between tabs', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_app(const MainShell()));

    expect(_selectedTab(tester), 0);
    expect(find.text('Safe to spend today').hitTestable(), findsOneWidget);

    await _tapNav(tester, 'Calendar');
    expect(_selectedTab(tester), 1);
    expect(find.text('October 2026').hitTestable(), findsOneWidget);
    expect(find.text('Safe to spend today').hitTestable(), findsNothing);

    await _tapNav(tester, 'Money Owed');
    expect(_selectedTab(tester), 3);
    expect(find.byKey(const Key('youOweCard')).hitTestable(), findsOneWidget);

    await _tapNav(tester, 'More');
    expect(_selectedTab(tester), 4);
    expect(
      find.text('Analytics, accounts and settings will appear here.')
          .hitTestable(),
      findsOneWidget,
    );

    await _tapNav(tester, 'Home');
    expect(_selectedTab(tester), 0);
    expect(find.text('Safe to spend today').hitTestable(), findsOneWidget);
  });

  testWidgets('Add opens the sheet with four choices and keeps the tab', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_app(const MainShell()));

    await _tapNav(tester, 'Add');

    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.text('Add Income'), findsOneWidget);
    expect(find.text('Add Money Owed'), findsOneWidget);
    expect(find.text('Add Recurring Expense'), findsOneWidget);

    await tester.tap(find.text('Add Recurring Expense'));
    await tester.pumpAndSettle();

    // The sheet is closed, a message appears, and we are still on Home.
    expect(find.text('Add Expense'), findsNothing);
    expect(
      find.text('Add Recurring Expense is built in a later step.'),
      findsOneWidget,
    );
    expect(_selectedTab(tester), 0);
    expect(find.text('Safe to spend today').hitTestable(), findsOneWidget);
  });

  testWidgets("Let's Get Started opens the main app", (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_app(const WelcomeScreen(displayName: 'Ashraf')));

    await tester.tap(find.byKey(const Key('getStartedButton')));
    await tester.pumpAndSettle();

    expect(find.text('Safe to spend today').hitTestable(), findsOneWidget);
    expect(find.text('Welcome, Ashraf!'), findsNothing);
  });
}