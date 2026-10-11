import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/theme/app_theme.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/calendar/application/calendar_store.dart';
import 'package:milbeki_app/features/calendar/data/mock_calendar_data.dart';
import 'package:milbeki_app/features/calendar/domain/calendar_events.dart';
import 'package:milbeki_app/features/calendar/domain/calendar_sources.dart';
import 'package:milbeki_app/features/calendar/presentation/calendar_display.dart';
import 'package:milbeki_app/features/calendar/presentation/calendar_screen.dart';
import 'package:milbeki_app/features/money_owed/application/debt_store.dart';
import 'package:milbeki_app/features/money_owed/data/mock_debt_data.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';

final _now = DateTime(2026, 10, 10, 15, 30); // a Saturday

// A tall virtual screen, so nothing is scrolled out of view during the test.
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

CalendarStore _sampleCalendar() => CalendarStore(
      bills: MockCalendarData.bills(),
      expectedIncome: MockCalendarData.expectedIncome(),
    );

Future<void> _pump(
  WidgetTester tester, {
  DebtStore? debtStore,
  CalendarStore? calendarStore,
}) async {
  _useTallScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: CalendarScreen(
          debtStore: debtStore ?? DebtStore(MockDebtData.sample()),
          calendarStore: calendarStore ?? _sampleCalendar(),
          now: () => _now,
        ),
      ),
    ),
  );
}

// Finds text inside the widget that has the given key.
Finder _inside(String key, String text) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.text(text));

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pump();
}

Future<void> _tapDay(WidgetTester tester, String iso) =>
    _tapKey(tester, 'day-$iso');

// The background colour of a day cell.
Color? _dayColor(WidgetTester tester, String iso) {
  final cell = tester.widget<Container>(find.byKey(Key('day-$iso')));
  return (cell.decoration as BoxDecoration).color;
}

Future<void> _openEvent(WidgetTester tester, String eventKey) async {
  await tester.tap(find.byKey(Key(eventKey)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens on the current month with its totals', (tester) async {
    await _pump(tester);

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);

    // Out: rent 5,000 + internet 1,000 + Fatir 300 = 6,300.
    // In: Sabbir 1,000 + Rahim 200 + tutoring 4,000 = 5,200.
    expect(_inside('monthOut', '৳6,300'), findsOneWidget);
    expect(_inside('monthIn', '৳5,200'), findsOneWidget);
    expect(
      find.text('Money coming in is not in your accounts until you receive it.'),
      findsOneWidget,
    );

    // Today is selected, and nothing is due today.
    expect(find.text('Sat, 10 Oct'), findsOneWidget);
    expect(find.text('Nothing on this day.'), findsOneWidget);
  });

  testWidgets('weeks start on Saturday', (tester) async {
    await _pump(tester);

    const names = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final xs = [for (final n in names) tester.getTopLeft(find.text(n)).dx];
    for (var i = 1; i < xs.length; i++) {
      expect(xs[i], greaterThan(xs[i - 1]), reason: '${names[i]} order');
    }
  });

  testWidgets('days are shaded by how many payments are due', (tester) async {
    await _pump(tester);

    // 15 Oct: rent only (Rahim is money coming in, so he does not count).
    expect(_dayColor(tester, '2026-10-15'), busyColor(BusyLevel.light));
    // 20 Oct: internet and Fatir.
    expect(_dayColor(tester, '2026-10-20'), busyColor(BusyLevel.medium));
    // 10 Oct has nothing; 1 Oct (Sabbir) and 25 Oct (tutoring) are money in only.
    expect(_dayColor(tester, '2026-10-10'), busyColor(BusyLevel.none));
    expect(_dayColor(tester, '2026-10-01'), busyColor(BusyLevel.none));
    expect(_dayColor(tester, '2026-10-25'), busyColor(BusyLevel.none));
  });

  testWidgets('three payments on one day is the heaviest shade', (tester) async {
    BillInstance bill(String id) => BillInstance(
          id: id,
          title: 'Bill $id',
          amount: Money.taka(100),
          dueDate: DateTime(2026, 10, 30),
        );

    await _pump(
      tester,
      debtStore: DebtStore([]),
      calendarStore: CalendarStore(
        bills: [bill('a'), bill('b'), bill('c')],
        expectedIncome: [],
      ),
    );

    expect(_dayColor(tester, '2026-10-30'), busyColor(BusyLevel.heavy));
  });

  testWidgets('the legend explains the shading in words', (tester) async {
    await _pump(tester);

    expect(find.text('1 payment'), findsOneWidget);
    expect(find.text('2 payments'), findsOneWidget);
    expect(find.text('3+ payments'), findsOneWidget);
    expect(find.text('Money coming in'), findsOneWidget);
  });

  testWidgets('tapping a day lists its events and totals', (tester) async {
    await _pump(tester);

    await _tapDay(tester, '2026-10-15');

    expect(find.text('Thu, 15 Oct'), findsOneWidget);
    expect(find.text('To pay ৳5,000 · Coming in ৳200'), findsOneWidget);
    expect(find.byKey(const Key('event-bill:bill-rent-oct')), findsOneWidget);
    expect(find.byKey(const Key('event-debt:debt-rahim')), findsOneWidget);
    expect(find.byKey(const Key('event-debt:debt-fatir')), findsNothing);

    expect(find.text('৳5,000'), findsOneWidget);
    expect(find.text('+৳200'), findsOneWidget); // money coming in has a plus
    expect(find.text('Bill · Due'), findsOneWidget);
    expect(
      find.text('Owed to you · Expected, not received yet'),
      findsOneWidget,
    );
  });

  group('overdue', () {
    testWidgets('the banner counts overdue items and Show jumps to the oldest', (tester) async {
      await _pump(tester);

      expect(find.text('1 overdue item'), findsOneWidget);

      await _tapKey(tester, 'showOverdueButton');

      expect(find.text('Thu, 1 Oct'), findsOneWidget);
      expect(find.byKey(const Key('event-debt:debt-sabbir')), findsOneWidget);
      expect(
        find.text('Owed to you · Overdue, not received yet'),
        findsOneWidget,
      );
    });

    testWidgets('Show also works from another month', (tester) async {
      await _pump(tester);

      await _tapKey(tester, 'nextMonthButton');
      expect(find.text('November 2026'), findsOneWidget);

      await _tapKey(tester, 'showOverdueButton');
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Thu, 1 Oct'), findsOneWidget);
    });

    testWidgets('with nothing overdue there is no banner', (tester) async {
      await _pump(tester, debtStore: DebtStore([]));

      expect(find.byKey(const Key('showOverdueButton')), findsNothing);
    });
  });

  group('month navigation', () {
    testWidgets('next and previous change the month, totals and selected day', (tester) async {
      await _pump(tester);

      await _tapKey(tester, 'nextMonthButton');
      expect(find.text('November 2026'), findsOneWidget);
      expect(_inside('monthOut', '৳400'), findsOneWidget); // mobile bill
      expect(_inside('monthIn', '৳10,000'), findsOneWidget); // allowance
      expect(find.text('Sun, 1 Nov'), findsOneWidget); // the 1st is selected
      expect(
        find.byKey(const Key('event-income:inc-allowance-nov')),
        findsOneWidget,
      );

      await _tapKey(tester, 'prevMonthButton');
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Sat, 10 Oct'), findsOneWidget); // back to today
    });

    testWidgets('an empty month shows zero totals, and Today returns', (tester) async {
      await _pump(tester);

      await _tapKey(tester, 'nextMonthButton');
      await _tapKey(tester, 'nextMonthButton');
      expect(find.text('December 2026'), findsOneWidget);
      expect(_inside('monthOut', '৳0'), findsOneWidget);
      expect(_inside('monthIn', '৳0'), findsOneWidget);

      await _tapKey(tester, 'todayButton');
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Sat, 10 Oct'), findsOneWidget);
    });

    testWidgets('moving forward crosses the year boundary', (tester) async {
      await _pump(tester);

      await _tapKey(tester, 'nextMonthButton');
      await _tapKey(tester, 'nextMonthButton');
      await _tapKey(tester, 'nextMonthButton');

      expect(find.text('January 2027'), findsOneWidget);
    });

    testWidgets('tapping a day from the next month jumps to that month', (tester) async {
      await _pump(tester);

      // 3 Nov is a filler cell at the end of October's grid.
      await _tapDay(tester, '2026-11-03');

      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('Tue, 3 Nov'), findsOneWidget);
      expect(find.byKey(const Key('event-bill:bill-mobile-nov')), findsOneWidget);
    });
  });

  testWidgets('filter chips hide and show kinds, and everything follows', (tester) async {
    await _pump(tester);

    // Hide bills.
    await _tapKey(tester, 'kind-bill');
    await _tapDay(tester, '2026-10-15');
    expect(find.byKey(const Key('event-bill:bill-rent-oct')), findsNothing);
    expect(find.byKey(const Key('event-debt:debt-rahim')), findsOneWidget);
    expect(_inside('monthOut', '৳300'), findsOneWidget); // only Fatir is left
    expect(_inside('monthIn', '৳5,200'), findsOneWidget);
    expect(_dayColor(tester, '2026-10-15'), busyColor(BusyLevel.none));

    // Also hide money owed to you: Sabbir (the overdue one) goes too.
    await _tapKey(tester, 'kind-owedToYou');
    expect(find.byKey(const Key('showOverdueButton')), findsNothing);
    expect(_inside('monthIn', '৳4,000'), findsOneWidget); // only tutoring

    // Bring bills back.
    await _tapKey(tester, 'kind-bill');
    expect(_inside('monthOut', '৳6,300'), findsOneWidget);
    expect(find.byKey(const Key('event-bill:bill-rent-oct')), findsOneWidget);
  });

  group('actions', () {
    testWidgets('a debt event opens the real debt, and paying it updates the calendar', (tester) async {
      await _pump(tester);

      await _tapDay(tester, '2026-10-20');
      await _openEvent(tester, 'event-debt:debt-fatir');
      expect(find.text('You owe Fatir'), findsOneWidget);

      await tester.tap(find.byKey(const Key('recordPaymentButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('payFullChip')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('savePaymentButton')));
      await tester.pumpAndSettle();
      expect(_inside('outstandingAmount', '৳0'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Fatir's 300 is gone. 20 Oct has only the internet bill left.
      expect(find.byKey(const Key('event-debt:debt-fatir')), findsNothing);
      expect(_dayColor(tester, '2026-10-20'), busyColor(BusyLevel.light));
      expect(_inside('monthOut', '৳6,000'), findsOneWidget); // 6,300 - 300
    });

    testWidgets('marking a bill as paid removes it from the calendar', (tester) async {
      final calendar = _sampleCalendar();
      await _pump(tester, calendarStore: calendar);

      await _tapDay(tester, '2026-10-15');
      await _openEvent(tester, 'event-bill:bill-rent-oct');

      expect(find.text('Mark as paid'), findsOneWidget);
      expect(find.textContaining('Sample only'), findsOneWidget);

      await tester.tap(find.byKey(const Key('markDoneButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event-bill:bill-rent-oct')), findsNothing);
      expect(find.textContaining('Marked as paid: House rent'), findsOneWidget);
      expect(_dayColor(tester, '2026-10-15'), busyColor(BusyLevel.none));
      expect(_inside('monthOut', '৳1,300'), findsOneWidget); // 6,300 - 5,000

      final rent = calendar.bills.firstWhere((b) => b.id == 'bill-rent-oct');
      expect(rent.paidAt, _now);
    });

    testWidgets('marking expected income as received removes it', (tester) async {
      await _pump(tester);

      await _tapDay(tester, '2026-10-25');
      await _openEvent(tester, 'event-income:inc-tutoring-oct');

      expect(find.text('Mark as received'), findsOneWidget);

      await tester.tap(find.byKey(const Key('markDoneButton')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('event-income:inc-tutoring-oct')),
        findsNothing,
      );
      expect(
        find.textContaining('Marked as received: ৳4,000'),
        findsOneWidget,
      );
      expect(_inside('monthIn', '৳1,200'), findsOneWidget); // 1,000 + 200
    });

    testWidgets('the sheet for an overdue bill says it is overdue', (tester) async {
      final late = BillInstance(
        id: 'late',
        title: 'Water bill',
        amount: Money.taka(300),
        dueDate: DateTime(2026, 10, 5),
      );
      await _pump(
        tester,
        debtStore: DebtStore([]),
        calendarStore: CalendarStore(bills: [late], expectedIncome: []),
      );

      expect(find.text('1 overdue item'), findsOneWidget);

      await _tapDay(tester, '2026-10-05');
      await _openEvent(tester, 'event-bill:late');

      expect(find.text('This bill is overdue.'), findsOneWidget);
    });
  });

  testWidgets('a debt added elsewhere shows up on the calendar', (tester) async {
    final debts = DebtStore(MockDebtData.sample());
    await _pump(tester, debtStore: debts);

    expect(_dayColor(tester, '2026-10-22'), busyColor(BusyLevel.none));

    debts.add(
      Debt(
        id: 'debt-new',
        personName: 'Tania',
        direction: DebtDirection.youOwe,
        originalAmount: Money.taka(220),
        startDate: DateTime(2026, 10, 10),
        dueDate: DateTime(2026, 10, 22),
      ),
    );
    await tester.pump();

    expect(_dayColor(tester, '2026-10-22'), busyColor(BusyLevel.light));
    expect(_inside('monthOut', '৳6,520'), findsOneWidget); // 6,300 + 220
  });
}