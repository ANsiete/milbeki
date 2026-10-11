import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/calendar/data/mock_calendar_data.dart';
import 'package:milbeki_app/features/calendar/domain/calendar_events.dart';
import 'package:milbeki_app/features/calendar/domain/calendar_sources.dart';
import 'package:milbeki_app/features/dashboard/data/mock_dashboard_data.dart';
import 'package:milbeki_app/features/dashboard/domain/dashboard_models.dart';
import 'package:milbeki_app/features/money_owed/data/mock_debt_data.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_rules.dart';

final _today = DateTime(2026, 10, 10, 15, 30);

List<CalendarEvent> _sample() => CalendarEvents.build(
      debts: MockDebtData.sample(),
      bills: MockCalendarData.bills(),
      expectedIncome: MockCalendarData.expectedIncome(),
    );

List<String> _ids(List<CalendarEvent> events) => events.map((e) => e.id).toList();

String _key(String title, Money amount, DateTime date) =>
    '$title|${amount.paisa}|${date.year}-${date.month}-${date.day}';

BillInstance _bill(String id, String title, DateTime due) => BillInstance(
      id: id,
      title: title,
      amount: Money.taka(100),
      dueDate: due,
    );

void main() {
  group('building the events', () {
    test('the sample data gives 8 events in date order', () {
      expect(_ids(_sample()), [
        'debt:debt-sabbir', //          1 Oct, owed to you, overdue
        'bill:bill-rent-oct', //        15 Oct
        'debt:debt-rahim', //           15 Oct (a bill sorts before money owed to you)
        'bill:bill-internet-oct', //    20 Oct
        'debt:debt-fatir', //           20 Oct
        'income:inc-tutoring-oct', //   25 Oct
        'income:inc-allowance-nov', //  1 Nov
        'bill:bill-mobile-nov', //      3 Nov
      ]);
    });

    test('finished items never appear', () {
      final ids = _ids(_sample());
      expect(ids.contains('debt:debt-mitu'), isFalse); // fully paid
      expect(ids.contains('debt:debt-karim'), isFalse); // cancelled
      expect(ids.contains('bill:bill-electricity-sep'), isFalse); // paid
      expect(ids.contains('income:inc-allowance-oct'), isFalse); // received
    });

    test('a skipped bill does not appear', () {
      final skipped = BillInstance(
        id: 'b1',
        title: 'Skipped',
        amount: Money.taka(100),
        dueDate: DateTime(2026, 10, 12),
        skippedAt: DateTime(2026, 10, 9),
      );
      final events = CalendarEvents.build(
        debts: [],
        bills: [skipped],
        expectedIncome: [],
      );
      expect(events, isEmpty);
    });

    test('debts show the outstanding amount, not the original', () {
      final events = _sample();
      final fatir = events.firstWhere((e) => e.sourceId == 'debt-fatir');
      final rahim = events.firstWhere((e) => e.sourceId == 'debt-rahim');

      expect(fatir.amount, Money.taka(300)); // 500 - 200 paid
      expect(fatir.kind, CalendarEventKind.debtYouOwe);
      expect(fatir.title, 'Repay Fatir');

      expect(rahim.amount, Money.taka(200)); // 300 - 100 received
      expect(rahim.kind, CalendarEventKind.owedToYou);
      expect(rahim.title, 'Rahim will pay you');
    });

    test('the time of day is dropped from the date', () {
      final events = CalendarEvents.build(
        debts: [],
        bills: [_bill('b1', 'Late bill', DateTime(2026, 10, 31, 15, 0))],
        expectedIncome: [],
      );
      expect(events.single.date, DateTime(2026, 10, 31));
    });

    test('building twice gives the same unique events (no duplicates)', () {
      final first = _ids(_sample());
      final second = _ids(_sample());
      expect(second, first);
      expect(first.toSet().length, first.length);
    });

    test('events on the same day sort by kind, then title, then id', () {
      final events = CalendarEvents.build(
        debts: [],
        bills: [
          _bill('b2', 'Zeta', DateTime(2026, 10, 12)),
          _bill('b1', 'Alpha', DateTime(2026, 10, 12, 18, 0)),
        ],
        expectedIncome: [],
      );
      expect(events.map((e) => e.title), ['Alpha', 'Zeta']);
    });
  });

  group('staying consistent with the records', () {
    test('a partial payment changes the calendar amount', () {
      final debts = MockDebtData.sample();
      final fatir = debts.firstWhere((d) => d.id == 'debt-fatir');
      final updated = fatir.withPayment(
        DebtPayment(
          id: 'p-test',
          amount: Money.taka(100),
          paidAt: DateTime(2026, 10, 9),
        ),
      );
      final changed = [for (final d in debts) d.id == 'debt-fatir' ? updated : d];

      final events = CalendarEvents.build(
        debts: changed,
        bills: [],
        expectedIncome: [],
      );
      final event = events.firstWhere((e) => e.sourceId == 'debt-fatir');
      expect(event.amount, Money.taka(200)); // 300 - 100
    });

    test('a fully paid debt leaves the calendar', () {
      final debts = MockDebtData.sample();
      final fatir = debts.firstWhere((d) => d.id == 'debt-fatir');
      final paid = fatir.withPayment(
        DebtPayment(
          id: 'p-full',
          amount: Money.taka(300),
          paidAt: DateTime(2026, 10, 9),
        ),
      );
      final changed = [for (final d in debts) d.id == 'debt-fatir' ? paid : d];

      final events = CalendarEvents.build(
        debts: changed,
        bills: [],
        expectedIncome: [],
      );
      expect(events.any((e) => e.sourceId == 'debt-fatir'), isFalse);
    });

    test('paying a bill removes it, and paying twice keeps the first time', () {
      final bills = MockCalendarData.bills();
      final rent = bills.firstWhere((b) => b.id == 'bill-rent-oct');

      final paid = rent.markPaid(DateTime(2026, 10, 12));
      final paidAgain = paid.markPaid(DateTime(2026, 10, 14));
      expect(paidAgain.paidAt, DateTime(2026, 10, 12));

      final events = CalendarEvents.build(
        debts: [],
        bills: [paid],
        expectedIncome: [],
      );
      expect(events, isEmpty);
    });

    test('receiving expected income removes it', () {
      final tutoring = MockCalendarData.expectedIncome()
          .firstWhere((i) => i.id == 'inc-tutoring-oct');

      final received = tutoring.markReceived(DateTime(2026, 10, 25, 11, 0));
      final receivedAgain = received.markReceived(DateTime(2026, 10, 26));
      expect(receivedAgain.receivedAt, DateTime(2026, 10, 25, 11, 0));

      final events = CalendarEvents.build(
        debts: [],
        bills: [],
        expectedIncome: [received],
      );
      expect(events, isEmpty);
    });

    test('the calendar and the dashboard show the same bills and debts', () {
      final events = _sample();
      final dashboardItems = MockDashboardData.sample().dueItems;

      final calendarBills = events
          .where((e) => e.kind == CalendarEventKind.bill)
          .map((e) => _key(e.title, e.amount, e.date))
          .toSet();
      final dashboardBills = dashboardItems
          .where((i) => i.kind == DueKind.bill)
          .map((i) => _key(i.title, i.amount, i.dueDate))
          .toSet();
      expect(calendarBills.length, 3);
      expect(calendarBills, dashboardBills);

      final calendarDebts = events
          .where((e) =>
              e.kind == CalendarEventKind.debtYouOwe ||
              e.kind == CalendarEventKind.owedToYou)
          .map((e) => _key(e.title, e.amount, e.date))
          .toSet();
      final dashboardDebts = DebtRules.toDueItems(MockDebtData.sample())
          .map((i) => _key(i.title, i.amount, i.dueDate))
          .toSet();
      expect(calendarDebts.length, 3);
      expect(calendarDebts, dashboardDebts);
    });
  });

  group('overdue', () {
    test('an overdue debt is flagged on its original date', () {
      final sabbir = _sample().firstWhere((e) => e.sourceId == 'debt-sabbir');
      expect(sabbir.date, DateTime(2026, 10, 1)); // stays on its own date
      expect(sabbir.isOverdueOn(_today), isTrue);
    });

    test('future items and items due today are not overdue', () {
      final rahim = _sample().firstWhere((e) => e.sourceId == 'debt-rahim');
      expect(rahim.isOverdueOn(_today), isFalse);

      final dueToday = CalendarEvent(
        id: 'bill:x',
        kind: CalendarEventKind.bill,
        title: 'Due today',
        amount: Money.taka(10),
        date: DateTime(2026, 10, 10),
        sourceId: 'x',
      );
      expect(dueToday.isOverdueOn(_today), isFalse);
      expect(dueToday.isOverdueOn(DateTime(2026, 10, 11)), isTrue);
    });
  });

  group('filtering', () {
    test('keeps only the chosen kinds', () {
      final events = _sample();

      expect(
        _ids(CalendarEvents.ofKinds(events, {CalendarEventKind.bill})),
        ['bill:bill-rent-oct', 'bill:bill-internet-oct', 'bill:bill-mobile-nov'],
      );
      expect(
        CalendarEvents.ofKinds(events, {
          CalendarEventKind.debtYouOwe,
          CalendarEventKind.owedToYou,
        }).length,
        3,
      );
      expect(
        CalendarEvents.ofKinds(events, CalendarEventKind.values.toSet()).length,
        8,
      );
      expect(CalendarEvents.ofKinds(events, {}), isEmpty);
    });

    test('inMonth keeps only that month', () {
      final events = _sample();
      expect(CalendarEvents.inMonth(events, 2026, 10).length, 6);
      expect(CalendarEvents.inMonth(events, 2026, 11).length, 2);
      expect(CalendarEvents.inMonth(events, 2026, 12), isEmpty);
    });
  });

  group('days and busy levels', () {
    test('events are grouped by day', () {
      final days = CalendarEvents.byDay(_sample());
      expect(days.keys.toSet(), {
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 15),
        DateTime(2026, 10, 20),
        DateTime(2026, 10, 25),
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 3),
      });
      expect(days[DateTime(2026, 10, 12)], isNull); // an empty day is absent
    });

    test('one bill and one money-in event: a light day', () {
      final day = CalendarEvents.byDay(_sample())[DateTime(2026, 10, 15)]!;
      expect(day.obligationCount, 1); // rent
      expect(day.moneyOut, Money.taka(5000));
      expect(day.moneyIn, Money.taka(200)); // Rahim
      expect(day.busyLevel, BusyLevel.light);
    });

    test('a bill plus a debt you owe: a medium day', () {
      final day = CalendarEvents.byDay(_sample())[DateTime(2026, 10, 20)]!;
      expect(day.obligationCount, 2);
      expect(day.moneyOut, Money.taka(1300)); // 1,000 + 300
      expect(day.moneyIn, Money.zero);
      expect(day.busyLevel, BusyLevel.medium);
    });

    test('days with only money coming in are not busy', () {
      final days = CalendarEvents.byDay(_sample());

      final overdueDay = days[DateTime(2026, 10, 1)]!; // Sabbir
      expect(overdueDay.obligationCount, 0);
      expect(overdueDay.moneyIn, Money.taka(1000));
      expect(overdueDay.busyLevel, BusyLevel.none);

      expect(days[DateTime(2026, 10, 25)]!.busyLevel, BusyLevel.none); // tutoring
    });

    test('three or more bills on one day is heavy', () {
      final three = CalendarEvents.build(
        debts: [],
        bills: [
          _bill('a', 'A', DateTime(2026, 10, 30)),
          _bill('b', 'B', DateTime(2026, 10, 30)),
          _bill('c', 'C', DateTime(2026, 10, 30)),
        ],
        expectedIncome: [],
      );
      expect(
        CalendarEvents.byDay(three)[DateTime(2026, 10, 30)]!.busyLevel,
        BusyLevel.heavy,
      );

      final four = CalendarEvents.build(
        debts: [],
        bills: [
          _bill('a', 'A', DateTime(2026, 10, 30)),
          _bill('b', 'B', DateTime(2026, 10, 30)),
          _bill('c', 'C', DateTime(2026, 10, 30)),
          _bill('d', 'D', DateTime(2026, 10, 30)),
        ],
        expectedIncome: [],
      );
      expect(
        CalendarEvents.byDay(four)[DateTime(2026, 10, 30)]!.busyLevel,
        BusyLevel.heavy,
      );
    });
  });

  group('totals', () {
    test('all sample events: money out and money in stay separate', () {
      final totals = EventTotals.of(_sample(), today: _today);
      // Out: rent 5,000 + internet 1,000 + mobile 400 + Fatir 300 = 6,700.
      expect(totals.moneyOut, Money.taka(6700));
      // In: Sabbir 1,000 + Rahim 200 + tutoring 4,000 + allowance 10,000 = 15,200.
      expect(totals.moneyIn, Money.taka(15200));
      expect(totals.overdueCount, 1); // Sabbir
    });

    test('October only', () {
      final october = CalendarEvents.inMonth(_sample(), 2026, 10);
      final totals = EventTotals.of(october, today: _today);
      // Out: 5,000 + 1,000 + 300 = 6,300. In: 1,000 + 200 + 4,000 = 5,200.
      expect(totals.moneyOut, Money.taka(6300));
      expect(totals.moneyIn, Money.taka(5200));
    });

    test('nothing gives zero', () {
      final totals = EventTotals.of([], today: _today);
      expect(totals.moneyOut, Money.zero);
      expect(totals.moneyIn, Money.zero);
      expect(totals.overdueCount, 0);
    });
  });
}