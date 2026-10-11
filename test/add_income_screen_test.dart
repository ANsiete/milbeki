import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/theme/app_theme.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/shell/main_shell.dart';
import 'package:milbeki_app/features/transactions/data/mock_income_lookups.dart';
import 'package:milbeki_app/features/transactions/data/mock_lookups.dart';
import 'package:milbeki_app/features/transactions/domain/income_models.dart';
import 'package:milbeki_app/features/transactions/presentation/add_income_screen.dart';

final _fixedNow = DateTime(2026, 10, 10, 15, 30); // a Saturday

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
  void Function(NewIncome?) onResult,
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
                final result = await Navigator.of(context).push<NewIncome>(
                  MaterialPageRoute(
                    builder: (_) => AddIncomeScreen(
                      sources: MockIncomeLookups.sources,
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

Future<void> _chooseStatus(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const Key('incomeStatusToggle')),
      matching: find.text(label),
    ),
  );
  await tester.pump();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('saveIncomeButton')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Saving an empty form shows errors and saves nothing', (tester) async {
    var called = false;
    await _launch(tester, (_) => called = true);

    await tester.tap(find.byKey(const Key('saveIncomeButton')));
    await tester.pump();

    expect(find.text('Enter an amount'), findsOneWidget);
    expect(find.text('Choose where the money came from'), findsOneWidget);
    expect(called, isFalse);
    expect(find.text('Add income'), findsOneWidget); // still on the form
  });

  testWidgets('A valid received income is returned with every field', (tester) async {
    NewIncome? saved;
    await _launch(tester, (r) => saved = r);

    await tester.enterText(find.byKey(const Key('incomeAmountField')), '5000');
    await tester.tap(find.text('Tutoring'));
    await tester.tap(find.textContaining('bKash'));
    await tester.enterText(
      find.byKey(const Key('incomeNoteField')),
      '  October tuition  ',
    );
    await _save(tester);

    expect(saved, isNotNull);
    expect(saved!.amount, Money.taka(5000));
    expect(saved!.source.id, 'tutoring');
    expect(saved!.status, IncomeStatus.received);
    expect(saved!.date, _fixedNow);
    expect(saved!.account?.id, 'bkash');
    expect(saved!.note, 'October tuition'); // spaces trimmed
  });

  testWidgets('The account defaults to Cash and an empty note is null', (tester) async {
    NewIncome? saved;
    await _launch(tester, (r) => saved = r);

    await tester.enterText(find.byKey(const Key('incomeAmountField')), '250.5');
    await tester.tap(find.text('Gift'));
    await _save(tester);

    expect(saved!.amount, Money.parse('250.50'));
    expect(saved!.account?.id, 'cash');
    expect(saved!.note, isNull);
  });

  testWidgets('Expected swaps the account and time for a date', (tester) async {
    var called = false;
    await _launch(tester, (_) => called = true);

    expect(find.text('Received into'), findsOneWidget);
    expect(find.text('When it arrived'), findsOneWidget);

    await _chooseStatus(tester, 'Expected');

    expect(find.text('Received into'), findsNothing);
    expect(find.text('When it arrived'), findsNothing);
    expect(find.text('When do you expect it?'), findsOneWidget);
    expect(find.textContaining('not counted in your balance'), findsOneWidget);

    // Without a date, saving is refused.
    await tester.enterText(find.byKey(const Key('incomeAmountField')), '3000');
    await tester.tap(find.text('Family allowance'));
    await tester.tap(find.byKey(const Key('saveIncomeButton')));
    await tester.pump();

    expect(find.text('Choose the expected date'), findsOneWidget);
    expect(called, isFalse);
  });

  testWidgets('A valid expected income has a date and no account', (tester) async {
    NewIncome? saved;
    await _launch(tester, (r) => saved = r);

    await _chooseStatus(tester, 'Expected');
    await tester.enterText(find.byKey(const Key('incomeAmountField')), '3000');
    await tester.tap(find.text('Family allowance'));
    await tester.tap(find.text('In 7 days'));
    await tester.pump();

    expect(find.text('Sat, 17 Oct'), findsOneWidget);

    await _save(tester);

    expect(saved, isNotNull);
    expect(saved!.status, IncomeStatus.expected);
    expect(saved!.source.id, 'allowance');
    expect(saved!.date, DateTime(2026, 10, 17));
    expect(saved!.account, isNull);
    expect(saved!.amount, Money.taka(3000));
  });

  testWidgets('The form explains that repayments are not income', (tester) async {
    await _launch(tester, (_) {});

    expect(find.textContaining('recorded under Money Owed'), findsOneWidget);
  });

  test('the sources do not include loans or repayments', () {
    for (final source in MockIncomeLookups.sources) {
      final name = source.name.toLowerCase();
      expect(name.contains('repay'), isFalse, reason: source.name);
      expect(name.contains('loan'), isFalse, reason: source.name);
      expect(name.contains('borrow'), isFalse, reason: source.name);
    }
  });

  testWidgets('Add > Add Income > Save returns to the app, and Home is unchanged', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const MainShell()),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Add'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Income'));
    await tester.pumpAndSettle();

    expect(find.byType(AddIncomeScreen), findsOneWidget);

    await tester.enterText(find.byKey(const Key('incomeAmountField')), '5000');
    await tester.tap(find.text('Tutoring'));
    await tester.tap(find.byKey(const Key('saveIncomeButton')));
    await tester.pumpAndSettle();

    expect(find.byType(AddIncomeScreen), findsNothing);
    expect(
      find.textContaining('Recorded ৳5,000 from Tutoring into Cash'),
      findsOneWidget,
    );

    // Nothing is stored yet, so the dashboard numbers do not move.
    expect(find.text('৳14,600').hitTestable(), findsOneWidget);
    expect(find.text('৳299').hitTestable(), findsOneWidget);
  });
}