import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/theme/app_theme.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/core/widgets/budget_progress.dart';
import 'package:milbeki_app/features/dashboard/data/mock_dashboard_data.dart';
import 'package:milbeki_app/features/dashboard/domain/dashboard_models.dart';
import 'package:milbeki_app/features/dashboard/presentation/dashboard_screen.dart';

// A copy of the sample data with a few values swapped, for edge-case tests.
DashboardData _variant({Money? moneyHeld, List<TodayExpense>? todayExpenses}) {
  final s = MockDashboardData.sample();
  return DashboardData(
    userName: s.userName,
    now: s.now,
    cycle: s.cycle,
    moneyHeld: moneyHeld ?? s.moneyHeld,
    periodIncome: s.periodIncome,
    periodExpenses: s.periodExpenses,
    monthlyBudget: s.monthlyBudget,
    savingsRemaining: s.savingsRemaining,
    categories: s.categories,
    todayExpenses: todayExpenses ?? s.todayExpenses,
    dueItems: s.dueItems,
  );
}

Future<void> _pump(WidgetTester tester, DashboardData data) async {
  // A tall screen, so the whole dashboard is visible without scrolling.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: DashboardScreen(data: data)),
    ),
  );
}

void main() {
  testWidgets('shows the greeting, date, and money held', (tester) async {
    await _pump(tester, MockDashboardData.sample());

    expect(find.text('Hello, Ashraf'), findsOneWidget);
    expect(find.text('Sat, 10 Oct'), findsOneWidget);
    expect(find.text('Money you hold'), findsOneWidget);
    expect(find.text('৳14,600'), findsOneWidget);
    expect(find.text('৳10,000'), findsOneWidget);
    expect(find.text('1 Oct to 31 Oct · 22 days left'), findsOneWidget);
  });

  testWidgets('shows the safe daily limit from the sample data', (tester) async {
    await _pump(tester, MockDashboardData.sample());

    expect(find.text('Safe to spend today'), findsOneWidget);
    expect(find.text('৳299'), findsOneWidget);
    expect(find.text('৳19 left today'), findsOneWidget);
    expect(find.text('22 days left in this cycle'), findsOneWidget);
  });

  testWidgets('the explanation panel shows every step of the calculation', (tester) async {
    await _pump(tester, MockDashboardData.sample());

    await tester.tap(find.text('How is this calculated?'));
    await tester.pumpAndSettle();

    expect(find.text('How your daily limit is calculated'), findsOneWidget);
    expect(find.text('-৳6,000'), findsOneWidget);
    expect(find.text('-৳300'), findsOneWidget);
    expect(find.text('-৳2,000'), findsOneWidget);
    expect(find.text('Spendable after commitments'), findsOneWidget);
    expect(find.text('৳6,300'), findsOneWidget);
    expect(find.text('+৳280'), findsOneWidget);
    expect(find.text('৳6,580'), findsOneWidget);
    expect(find.text('Your daily limit (rounded down)'), findsOneWidget);
  });

  testWidgets('budget overview shows totals and a category warning', (tester) async {
    await _pump(tester, MockDashboardData.sample());

    expect(find.text('Monthly budget'), findsOneWidget);
    expect(find.text('৳500 of ৳8,000'), findsOneWidget);
    expect(find.text('৳7,500'), findsOneWidget); // remaining
    // Transport is 100 of 120, which is 83% used.
    expect(find.text('83% used. Close to the limit.'), findsOneWidget);
  });

  testWidgets("today's spending lists newest first", (tester) async {
    await _pump(tester, MockDashboardData.sample());

    expect(find.text('3 transactions'), findsOneWidget);
    expect(find.text('৳280'), findsOneWidget);
    expect(find.text('Food · 1:10 PM'), findsOneWidget);

    final lunchY = tester.getTopLeft(find.text('Lunch')).dy;
    final breakfastY = tester.getTopLeft(find.text('Breakfast')).dy;
    expect(lunchY, lessThan(breakfastY));
  });

  testWidgets('upcoming items are in date order and show money owed to you separately', (tester) async {
    await _pump(tester, MockDashboardData.sample());

    final rentY = tester.getTopLeft(find.text('House rent')).dy;
    final internetY = tester.getTopLeft(find.text('Internet')).dy;
    final mobileY = tester.getTopLeft(find.text('Mobile bill')).dy;
    expect(rentY, lessThan(internetY));
    expect(internetY, lessThan(mobileY));

    expect(find.text('Rahim will pay you'), findsOneWidget);
    expect(find.text('+৳200'), findsOneWidget);
    expect(find.text('Expected 15 Oct. Not received yet.'), findsOneWidget);
    expect(find.text('Due 3 Nov'), findsOneWidget);
  });

  testWidgets('a shortfall shows zero and says how much is missing', (tester) async {
    await _pump(tester, _variant(moneyHeld: Money.taka(1000)));

    expect(find.text('৳0'), findsOneWidget);
    expect(find.textContaining('৳7,300 more'), findsOneWidget);
    expect(find.textContaining('left today'), findsNothing);
  });

  testWidgets('spending past the limit says how far over you are', (tester) async {
    final bigSpend = [
      TodayExpense(
        title: 'Big purchase',
        categoryName: 'Shopping',
        amount: Money.taka(500),
        time: DateTime(2026, 10, 10, 12, 0),
      ),
    ];
    await _pump(tester, _variant(todayExpenses: bigSpend));

    expect(find.text("Over today's limit by ৳191"), findsOneWidget);
    expect(find.text('1 transaction'), findsOneWidget);
  });

  testWidgets('a quick action shows a message for now', (tester) async {
    await _pump(tester, MockDashboardData.sample());

    await tester.tap(find.text('Expense'));
    await tester.pump();

    expect(find.text('Expense is built in a later step.'), findsOneWidget);
  });

  group('budget helpers', () {
    test('budgetPercent rounds down and is not capped', () {
      expect(budgetPercent(Money.taka(240), Money.taka(3000)), 8);
      expect(budgetPercent(Money.taka(100), Money.taka(120)), 83);
      expect(budgetPercent(Money.taka(150), Money.taka(100)), 150);
    });

    test('a zero budget is 0% with no spending and 100% with spending', () {
      expect(budgetPercent(Money.zero, Money.zero), 0);
      expect(budgetPercent(Money.taka(10), Money.zero), 100);
    });

    test('budgetStatus warns at 80% and flags over 100%', () {
      expect(budgetStatus(79), BudgetStatus.ok);
      expect(budgetStatus(80), BudgetStatus.nearLimit);
      expect(budgetStatus(100), BudgetStatus.nearLimit);
      expect(budgetStatus(101), BudgetStatus.over);
    });
  });
}