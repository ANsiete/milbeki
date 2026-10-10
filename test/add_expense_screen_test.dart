import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/theme/app_theme.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/dashboard/data/mock_dashboard_data.dart';
import 'package:milbeki_app/features/shell/main_shell.dart';
import 'package:milbeki_app/features/transactions/data/mock_lookups.dart';
import 'package:milbeki_app/features/transactions/domain/transaction_models.dart';
import 'package:milbeki_app/features/transactions/presentation/add_expense_screen.dart';

final _fixedNow = DateTime(2026, 10, 10, 15, 30);

// A tall virtual screen, so nothing is scrolled out of view during the test.
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// Shows a button that opens the form, and reports what the form returns.
Future<void> _launch(
  WidgetTester tester,
  void Function(NewExpense?) onResult,
) async {
  _useTallScreen(tester);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<NewExpense>(
                  MaterialPageRoute(
                    builder: (_) => AddExpenseScreen(
                      categories: MockLookups.expenseCategories,
                      accounts: MockLookups.accounts,
                      now: () => _fixedNow,
                    ),
                  ),
                );
                onResult(result);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

String _amountText(WidgetTester tester) {
  final field = tester.widget<TextField>(
    find.descendant(
      of: find.byKey(const Key('amountField')),
      matching: find.byType(TextField),
    ),
  );
  return field.controller!.text;
}

void main() {
  testWidgets('Saving an empty form shows errors and saves nothing', (tester) async {
    var called = false;
    await _launch(tester, (_) => called = true);

    await tester.tap(find.byKey(const Key('saveExpenseButton')));
    await tester.pump();

    expect(find.text('Enter an amount'), findsOneWidget);
    expect(find.text('Choose a category'), findsOneWidget);
    expect(called, isFalse);
    expect(find.text('Add expense'), findsOneWidget); // still on the form
  });

  testWidgets('A valid expense is returned with every field', (tester) async {
    NewExpense? saved;
    var called = false;
    await _launch(tester, (r) {
      saved = r;
      called = true;
    });

    await tester.enterText(find.byKey(const Key('amountField')), '120.5');
    await tester.tap(find.text('Food'));
    await tester.tap(find.textContaining('bKash'));
    await tester.enterText(find.byKey(const Key('descriptionField')), 'Lunch');
    await tester.tap(find.byKey(const Key('saveExpenseButton')));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(saved, isNotNull);
    expect(saved!.amount, Money.parse('120.50'));
    expect(saved!.category.id, 'food');
    expect(saved!.account.id, 'bkash');
    expect(saved!.occurredAt, _fixedNow);
    expect(saved!.description, 'Lunch');
  });

  testWidgets('The account defaults to Cash and an empty description is null', (tester) async {
    NewExpense? saved;
    await _launch(tester, (r) => saved = r);

    await tester.enterText(find.byKey(const Key('amountField')), '40');
    await tester.tap(find.text('Transport'));
    await tester.tap(find.byKey(const Key('saveExpenseButton')));
    await tester.pumpAndSettle();

    expect(saved!.account.id, 'cash');
    expect(saved!.description, isNull);
  });

  testWidgets('The amount field blocks letters and a third decimal place', (tester) async {
    await _launch(tester, (_) {});

    await tester.enterText(find.byKey(const Key('amountField')), 'abc');
    expect(_amountText(tester), '');

    await tester.enterText(find.byKey(const Key('amountField')), '1.234');
    expect(_amountText(tester), '1.23');
  });

  testWidgets('Spending more than the account holds shows a warning', (tester) async {
    await _launch(tester, (_) {});

    await tester.enterText(find.byKey(const Key('amountField')), '50');
    await tester.tap(find.textContaining('Nagad')); // Nagad holds ৳0
    await tester.pump();
    expect(find.textContaining('more than the Nagad balance'), findsOneWidget);

    await tester.tap(find.textContaining('Cash')); // Cash holds ৳2,600
    await tester.pump();
    expect(find.textContaining('more than the'), findsNothing);
  });

  testWidgets('Add > Add Expense > Save returns to the app with a message', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const MainShell()),
    );

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Expense'));
    await tester.pumpAndSettle();

    expect(find.byType(AddExpenseScreen), findsOneWidget);

    await tester.enterText(find.byKey(const Key('amountField')), '250');
    await tester.tap(
      find.descendant(
        of: find.byType(AddExpenseScreen),
        matching: find.text('Food'),
      ),
    );
    await tester.tap(find.byKey(const Key('saveExpenseButton')));
    await tester.pumpAndSettle();

    expect(find.byType(AddExpenseScreen), findsNothing);
    expect(
      find.textContaining('Recorded ৳250 for Food from Cash'),
      findsOneWidget,
    );
  });

  test('sample accounts add up to the money held on the dashboard', () {
    final total = MockLookups.accounts
        .fold<Money>(Money.zero, (sum, a) => sum + a.balance);
    expect(total, MockDashboardData.sample().moneyHeld);
  });
}