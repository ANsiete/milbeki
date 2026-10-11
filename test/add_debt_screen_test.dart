import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/theme/app_theme.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/money_owed/application/debt_store.dart';
import 'package:milbeki_app/features/money_owed/data/mock_debt_data.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';
import 'package:milbeki_app/features/money_owed/presentation/add_debt_screen.dart';
import 'package:milbeki_app/features/money_owed/presentation/money_owed_screen.dart';
import 'package:milbeki_app/features/shell/main_shell.dart';

final _fixedNow = DateTime(2026, 10, 10, 15, 30); // a Saturday

// A tall virtual screen, so nothing is scrolled out of view during the test.
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// Finds text inside the widget that has the given key.
Finder _inside(String key, String text) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.text(text));

// Taps a bottom-bar item, looking only inside the NavigationBar.
Future<void> _tapNav(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

// Fills in the Add money owed form, using a quick-pick chip for the due date.
Future<void> _fillForm(
  WidgetTester tester, {
  required String direction,
  required String name,
  required String amount,
  required String chip,
  String? description,
}) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const Key('debtDirectionToggle')),
      matching: find.text(direction),
    ),
  );
  await tester.pump();
  await tester.enterText(find.byKey(const Key('debtNameField')), name);
  await tester.enterText(find.byKey(const Key('debtAmountField')), amount);
  await tester.tap(find.text(chip));
  await tester.pump();
  if (description != null) {
    await tester.enterText(
      find.byKey(const Key('debtDescriptionField')),
      description,
    );
  }
}

// Shows a button that opens the form, and reports what the form returns.
Future<void> _launchForm(
  WidgetTester tester,
  void Function(Debt?) onResult,
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
                final result = await Navigator.of(context).push<Debt>(
                  MaterialPageRoute(
                    builder: (_) => AddDebtScreen(now: () => _fixedNow),
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

Future<void> _openFormFromShell(WidgetTester tester) async {
  await _tapNav(tester, 'Add');
  await tester.tap(find.text('Add Money Owed'));
  await tester.pumpAndSettle();
}

Future<void> _saveForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('saveDebtButton')));
  await tester.pumpAndSettle();
}

void main() {
  group('the form', () {
    testWidgets('an empty form shows every error and saves nothing', (tester) async {
      var called = false;
      await _launchForm(tester, (_) => called = true);

      await tester.tap(find.byKey(const Key('saveDebtButton')));
      await tester.pump();

      expect(find.text('Choose who owes whom'), findsOneWidget);
      expect(find.text("Enter the person's name"), findsOneWidget);
      expect(find.text('Enter an amount'), findsOneWidget);
      expect(find.text('Choose a due date'), findsOneWidget);
      expect(called, isFalse);
      expect(find.text('Add money owed'), findsOneWidget); // still on the form
    });

    testWidgets('a valid debt is returned with every field', (tester) async {
      Debt? saved;
      await _launchForm(tester, (r) => saved = r);

      await _fillForm(
        tester,
        direction: 'You owe',
        name: '  Tania  ',
        amount: '750.5',
        chip: 'In 14 days',
        description: 'Concert ticket',
      );
      await _saveForm(tester);

      expect(saved, isNotNull);
      expect(saved!.id, isNotEmpty);
      expect(saved!.direction, DebtDirection.youOwe);
      expect(saved!.personName, 'Tania'); // spaces trimmed
      expect(saved!.originalAmount, Money.parse('750.50'));
      expect(saved!.startDate, DateTime(2026, 10, 10));
      expect(saved!.dueDate, DateTime(2026, 10, 24));
      expect(saved!.description, 'Concert ticket');
      expect(saved!.payments, isEmpty);
      expect(saved!.outstanding, Money.parse('750.50'));
      expect(saved!.statusOn(_fixedNow), DebtStatus.pending);
    });

    testWidgets('an empty reason is saved as null', (tester) async {
      Debt? saved;
      await _launchForm(tester, (r) => saved = r);

      await _fillForm(
        tester,
        direction: 'Owed to you',
        name: 'Rahim',
        amount: '300',
        chip: 'In 7 days',
      );
      await _saveForm(tester);

      expect(saved!.direction, DebtDirection.owedToYou);
      expect(saved!.description, isNull);
      expect(saved!.dueDate, DateTime(2026, 10, 17));
    });

    testWidgets('a zero amount is rejected', (tester) async {
      var called = false;
      await _launchForm(tester, (_) => called = true);

      await _fillForm(
        tester,
        direction: 'You owe',
        name: 'Tania',
        amount: '0',
        chip: 'In 7 days',
      );
      await tester.tap(find.byKey(const Key('saveDebtButton')));
      await tester.pump();

      expect(find.text('Amount must be greater than 0'), findsOneWidget);
      expect(called, isFalse);
    });

    testWidgets('quick-pick chips set the due date from the start date', (tester) async {
      await _launchForm(tester, (_) {});

      expect(find.text('Choose due date'), findsOneWidget);

      await tester.tap(find.text('In 7 days'));
      await tester.pump();
      expect(find.text('Sat, 17 Oct'), findsOneWidget);

      await tester.tap(find.text('In 30 days'));
      await tester.pump();
      expect(find.text('Mon, 9 Nov'), findsOneWidget);
    });

    testWidgets('choosing a direction explains what it means', (tester) async {
      await _launchForm(tester, (_) {});

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('debtDirectionToggle')),
          matching: find.text('Owed to you'),
        ),
      );
      await tester.pump();
      expect(
        find.text('You lent this money and expect it back.'),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('debtDirectionToggle')),
          matching: find.text('You owe'),
        ),
      );
      await tester.pump();
      expect(
        find.text('You borrowed this money and must pay it back.'),
        findsOneWidget,
      );
    });
  });

  group('shared debts', () {
    testWidgets('the Add debt button on Money Owed adds a debt to the list', (tester) async {
      _useTallScreen(tester);
      final store = DebtStore(MockDebtData.sample());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: MoneyOwedScreen(store: store, now: () => _fixedNow),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('addDebtButton')));
      await tester.pumpAndSettle();
      expect(find.byType(AddDebtScreen), findsOneWidget);

      await _fillForm(
        tester,
        direction: 'You owe',
        name: 'Tania',
        amount: '220',
        chip: 'In 14 days',
      );
      await _saveForm(tester);

      expect(find.byType(AddDebtScreen), findsNothing);
      expect(store.debts.length, 6);
      expect(find.text('Tania'), findsOneWidget);
      // You owe: Fatir 300 + Tania 220 = 520.
      expect(_inside('youOweCard', '৳520'), findsOneWidget);
    });

    testWidgets('+ > Add Money Owed adds a debt owed to you, and Home is unchanged', (tester) async {
      _useTallScreen(tester);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const MainShell()),
      );

      await _openFormFromShell(tester);
      expect(find.byType(AddDebtScreen), findsOneWidget);

      await _fillForm(
        tester,
        direction: 'Owed to you',
        name: 'Tania',
        amount: '500',
        chip: 'In 14 days',
      );
      await _saveForm(tester);

      expect(find.byType(AddDebtScreen), findsNothing);
      expect(
        find.textContaining('Recorded: Tania owes you ৳500'),
        findsOneWidget,
      );

      // Money Owed: others owe you 1,200 + 500 = 1,700.
      await _tapNav(tester, 'Money Owed');
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('directionToggle')),
          matching: find.text('Owed to you'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tania'), findsOneWidget);
      expect(_inside('owedToYouCard', '৳1,700'), findsOneWidget);

      // Home: money owed to you never changes the safe limit, and the debt
      // did not move any money between accounts.
      await _tapNav(tester, 'Home');
      expect(find.text('৳299').hitTestable(), findsOneWidget);
      expect(find.text('৳14,600').hitTestable(), findsOneWidget);
    });

    testWidgets('a new debt you owe lowers the safe limit on Home', (tester) async {
      _useTallScreen(tester);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const MainShell()),
      );

      await _openFormFromShell(tester);
      await _fillForm(
        tester,
        direction: 'You owe',
        name: 'Tania',
        amount: '220',
        chip: 'In 14 days', // 24 Oct, before the cycle ends on 31 Oct
      );
      await _saveForm(tester);

      await _tapNav(tester, 'Home');

      // Debts due = 300 + 220 = 520.
      // Spendable = 14,600 - 6,000 - 520 - 2,000 = 6,080.
      // Start of day = 6,080 + 280 spent today = 6,360. 6,360 / 22 = 289.09.
      expect(find.text('৳289').hitTestable(), findsOneWidget);
      expect(find.text('৳9 left today').hitTestable(), findsOneWidget);
      expect(find.text('Repay Tania').hitTestable(), findsOneWidget);
    });

    testWidgets('recording a payment on Money Owed updates Home', (tester) async {
      _useTallScreen(tester);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const MainShell()),
      );

      await _tapNav(tester, 'Money Owed');
      await tester.tap(find.byKey(const Key('debtCard-debt-fatir')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recordPaymentButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('paymentAmountField')),
        '100',
      );
      await tester.tap(find.byKey(const Key('savePaymentButton')));
      await tester.pumpAndSettle();

      await tester.pageBack(); // from the debt details back to the list
      await tester.pumpAndSettle();
      await _tapNav(tester, 'Home');

      // Fatir now has 200 left. Spendable = 14,600 - 6,000 - 200 - 2,000 = 6,400.
      // Start of day = 6,400 + 280 = 6,680. 6,680 / 22 = 303.6, shown as 303.
      expect(find.text('৳303').hitTestable(), findsOneWidget);
      expect(find.text('৳23 left today').hitTestable(), findsOneWidget);
    });
  });
}