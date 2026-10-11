import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/theme/app_theme.dart';
import 'package:milbeki_app/features/money_owed/data/mock_debt_data.dart';
   import 'package:milbeki_app/features/money_owed/application/debt_store.dart';
import 'package:milbeki_app/features/money_owed/presentation/money_owed_screen.dart';

final _now = DateTime(2026, 10, 10, 15, 30);

// A tall virtual screen, so nothing is scrolled out of view during the test.
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pump(WidgetTester tester) async {
  _useTallScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: MoneyOwedScreen(
             store: DebtStore(MockDebtData.sample()),
          now: () => _now,
        ),
      ),
    ),
  );
}

// Finds text inside the widget that has the given key.
Finder _inside(String key, String text) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.text(text));

// Vertical position of a keyed widget; a smaller number is higher on screen.
double _y(WidgetTester tester, String key) =>
    tester.getTopLeft(find.byKey(Key(key))).dy;

String _fieldText(WidgetTester tester, String key) {
  final field = tester.widget<TextField>(
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField)),
  );
  return field.controller!.text;
}

Future<void> _showOwedToYou(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const Key('directionToggle')),
      matching: find.text('Owed to you'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, String debtId) async {
  await tester.tap(find.byKey(Key('debtCard-$debtId')));
  await tester.pumpAndSettle();
}

Future<void> _openPaymentForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('recordPaymentButton')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('summary cards show gross totals and overdue amounts', (tester) async {
    await _pump(tester);

    expect(_inside('youOweCard', '৳300'), findsOneWidget);
    expect(_inside('youOweCard', 'Nothing overdue'), findsOneWidget);
    expect(_inside('owedToYouCard', '৳1,200'), findsOneWidget);
    expect(_inside('owedToYouCard', 'Overdue ৳1,000'), findsOneWidget);
    expect(find.text('2 partially settled'), findsOneWidget);
  });

  testWidgets('only debts due within 7 days appear in the due-soon panel', (tester) async {
    await _pump(tester);

    expect(find.byKey(const Key('dueSoon-debt-rahim')), findsOneWidget);
    expect(find.byKey(const Key('dueSoon-debt-fatir')), findsNothing);
    expect(find.byKey(const Key('dueSoon-debt-sabbir')), findsNothing);
  });

  testWidgets('starts on "You owe", ordered by due date', (tester) async {
    await _pump(tester);

    expect(find.byKey(const Key('debtCard-debt-mitu')), findsOneWidget);
    expect(find.byKey(const Key('debtCard-debt-fatir')), findsOneWidget);
    expect(find.byKey(const Key('debtCard-debt-rahim')), findsNothing);
    expect(
      _y(tester, 'debtCard-debt-mitu'),
      lessThan(_y(tester, 'debtCard-debt-fatir')),
    );
  });

  testWidgets('"Owed to you" lists its own debts in due-date order', (tester) async {
    await _pump(tester);
    await _showOwedToYou(tester);

    expect(find.byKey(const Key('debtCard-debt-mitu')), findsNothing);
    expect(
      _y(tester, 'debtCard-debt-sabbir'),
      lessThan(_y(tester, 'debtCard-debt-karim')),
    );
    expect(
      _y(tester, 'debtCard-debt-karim'),
      lessThan(_y(tester, 'debtCard-debt-rahim')),
    );
  });

  testWidgets('the Overdue filter keeps only overdue debts', (tester) async {
    await _pump(tester);
    await _showOwedToYou(tester);

    await tester.tap(find.byKey(const Key('filter-overdue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('debtCard-debt-sabbir')), findsOneWidget);
    expect(find.byKey(const Key('debtCard-debt-karim')), findsNothing);
    expect(find.byKey(const Key('debtCard-debt-rahim')), findsNothing);

    await tester.tap(find.byKey(const Key('filter-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('debtCard-debt-karim')), findsOneWidget);
  });

  testWidgets('searching by name narrows the list', (tester) async {
    await _pump(tester);
    await _showOwedToYou(tester);

    await tester.enterText(find.byKey(const Key('debtSearchField')), 'sab');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('debtCard-debt-sabbir')), findsOneWidget);
    expect(find.byKey(const Key('debtCard-debt-rahim')), findsNothing);

    await tester.enterText(find.byKey(const Key('debtSearchField')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No debts match your search or filter.'), findsOneWidget);
  });

  testWidgets('sorting by amount puts the larger balance first', (tester) async {
    await _pump(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('sortToggle')),
        matching: find.text('Amount'),
      ),
    );
    await tester.pumpAndSettle();

    // Fatir still owes 300; Mitu owes nothing.
    expect(
      _y(tester, 'debtCard-debt-fatir'),
      lessThan(_y(tester, 'debtCard-debt-mitu')),
    );
  });

  testWidgets('opening a debt shows its amounts and payment history', (tester) async {
    await _pump(tester);
    await _open(tester, 'debt-fatir');

    expect(find.text('You owe Fatir'), findsOneWidget);
    expect(find.text('Payments you made'), findsOneWidget);
    expect(find.text('Paid ৳200 of ৳500'), findsOneWidget);
    expect(_inside('outstandingAmount', '৳300'), findsOneWidget);
    expect(find.textContaining('Paid by bKash'), findsOneWidget);
    expect(find.byKey(const Key('recordPaymentButton')), findsOneWidget);
  });

  testWidgets('recording a payment updates the debt and the totals', (tester) async {
    await _pump(tester);
    await _open(tester, 'debt-fatir');
    await _openPaymentForm(tester);

    await tester.enterText(find.byKey(const Key('paymentAmountField')), '100');
    await tester.enterText(
      find.byKey(const Key('paymentNoteField')),
      'Cash handover',
    );
    await tester.tap(find.byKey(const Key('savePaymentButton')));
    await tester.pumpAndSettle();

    // Back on the detail screen, with the new balance and history.
    expect(find.text('Record payment'), findsNothing);
    expect(_inside('outstandingAmount', '৳200'), findsOneWidget);
    expect(find.textContaining('Recorded ৳100'), findsOneWidget);
    expect(find.textContaining('Cash handover'), findsOneWidget);

    // Back on the list, the totals follow.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_inside('youOweCard', '৳200'), findsOneWidget);
    expect(_inside('debtCard-debt-fatir', '৳200'), findsOneWidget);
  });

  testWidgets('a payment larger than the outstanding amount is rejected', (tester) async {
    await _pump(tester);
    await _open(tester, 'debt-fatir');
    await _openPaymentForm(tester);

    await tester.enterText(find.byKey(const Key('paymentAmountField')), '301');
    await tester.tap(find.byKey(const Key('savePaymentButton')));
    await tester.pump();

    expect(
      find.text('Payment cannot be more than the outstanding ৳300'),
      findsOneWidget,
    );
    expect(find.text('Record payment'), findsOneWidget); // still on the form
  });

  testWidgets('an empty amount is rejected', (tester) async {
    await _pump(tester);
    await _open(tester, 'debt-fatir');
    await _openPaymentForm(tester);

    await tester.tap(find.byKey(const Key('savePaymentButton')));
    await tester.pump();

    expect(find.text('Enter an amount'), findsOneWidget);
    expect(find.text('Record payment'), findsOneWidget);
  });

  testWidgets('"Pay full" fills the field with the outstanding amount', (tester) async {
    await _pump(tester);
    await _open(tester, 'debt-fatir');
    await _openPaymentForm(tester);

    await tester.tap(find.byKey(const Key('payFullChip')));
    await tester.pump();

    expect(_fieldText(tester, 'paymentAmountField'), '300');
  });

  testWidgets('receiving the full repayment settles the debt', (tester) async {
    await _pump(tester);
    await _showOwedToYou(tester);
    await _open(tester, 'debt-rahim');

    expect(find.text('Rahim owes you'), findsOneWidget);
    expect(find.text('Payments you received'), findsOneWidget);
    expect(find.text('Record a payment I received'), findsOneWidget);

    await _openPaymentForm(tester);
    await tester.tap(find.byKey(const Key('payFullChip')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('savePaymentButton')));
    await tester.pumpAndSettle();

    expect(_inside('outstandingAmount', '৳0'), findsOneWidget);
    expect(find.text('This debt is fully paid.'), findsOneWidget);
    expect(find.byKey(const Key('recordPaymentButton')), findsNothing);

    // The total owed to you drops by what was received: 1,200 - 200.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_inside('owedToYouCard', '৳1,000'), findsOneWidget);
  });

  testWidgets('a fully paid debt cannot take another payment', (tester) async {
    await _pump(tester);
    await _open(tester, 'debt-mitu');

    expect(find.text('This debt is fully paid.'), findsOneWidget);
    expect(find.byKey(const Key('recordPaymentButton')), findsNothing);
  });

  testWidgets('a cancelled debt cannot take a payment', (tester) async {
    await _pump(tester);
    await _showOwedToYou(tester);
    await _open(tester, 'debt-karim');

    expect(
      find.text('This debt was cancelled. No more payments can be recorded.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('recordPaymentButton')), findsNothing);
  });
}