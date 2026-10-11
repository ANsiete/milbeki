import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/budget_cycle.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/calendar/domain/calendar_events.dart';
import 'package:milbeki_app/features/dashboard/domain/daily_limit.dart';
import 'package:milbeki_app/features/dashboard/domain/dashboard_models.dart';
import 'package:milbeki_app/features/setup/domain/setup_models.dart';
import 'package:milbeki_app/features/setup/domain/setup_records.dart';

import 'support/setup_scenario.dart';

IncomeEntry _income(String id, String name, int day,
        {SetupFrequency frequency = SetupFrequency.monthly}) =>
    IncomeEntry(
      id: id,
      name: name,
      amount: Money.taka(100),
      frequency: frequency,
      dayOfMonth: day,
    );

FixedExpenseEntry _bill(String id, String title, int? day,
        {SetupFrequency frequency = SetupFrequency.monthly,
        bool paid = false}) =>
    FixedExpenseEntry(
      id: id,
      kind: FixedExpenseKind.other,
      title: title,
      amount: Money.taka(100),
      frequency: frequency,
      dayOfMonth: day,
      paidThisCycle: paid,
    );

void main() {
  group('the sample setup (cycle 1 to 31 Oct, today 10 Oct)', () {
    final records = SetupRecords.from(sampleSetup(), now: setupNow);

    test('creates the accounts with their opening balances', () {
      expect(records.accounts.map((a) => a.name), ['Cash', 'bKash']);
      expect(records.moneyHeld, Money.taka(14600));
    });

    test('creates expected income only for days that are still to come', () {
      // Allowance is on the 1st (already past); tutoring is on the 25th.
      expect(records.expectedIncome.map((i) => i.id), ['setup-income-inc-tutoring']);

      final tutoring = records.expectedIncome.single;
      expect(tutoring.sourceName, 'Tutoring');
      expect(tutoring.amount, Money.taka(4000));
      expect(tutoring.expectedOn, DateTime(2026, 10, 25));

      // The allowance already arrived. It is assumed to be in the balances.
      expect(records.alreadyDueIncome, ['Family allowance']);
    });

    test('creates unpaid monthly bills, and none for a bill marked paid', () {
      expect(
        records.bills.map((b) => b.id),
        ['setup-bill-fx-rent', 'setup-bill-fx-internet'],
      );
      expect(records.bills[0].dueDate, DateTime(2026, 10, 15));
      expect(records.bills[0].amount, Money.taka(5000));
      expect(records.bills[1].dueDate, DateTime(2026, 10, 20));
      expect(records.bills.any((b) => b.title == 'Electricity'), isFalse);
    });

    test('nothing is already paid or received', () {
      expect(records.bills.every((b) => b.isOpen), isTrue);
      expect(records.expectedIncome.every((i) => i.isOpen), isTrue);
    });

    test('what setup creates appears on the calendar', () {
      final events = CalendarEvents.build(
        debts: [],
        bills: records.bills,
        expectedIncome: records.expectedIncome,
      );

      expect(events.map((e) => e.id), [
        'bill:setup-bill-fx-rent', //            15 Oct
        'bill:setup-bill-fx-internet', //        20 Oct
        'income:setup-income-inc-tutoring', //   25 Oct
      ]);
    });

    test('the setup feeds the daily limit', () {
      final data = sampleSetup();
      final dueItems = [
        for (final bill in records.bills)
          DueItem(
            title: bill.title,
            amount: bill.amount,
            dueDate: bill.dueDate,
            kind: DueKind.bill,
          ),
      ];

      final limit = DailyLimitCalculator.calculate(
        moneyHeld: records.moneyHeld,
        dueItems: dueItems,
        savingsRemaining: data.savings.monthlyTarget,
        spentToday: Money.zero,
        cycle: BudgetCycle.containing(setupNow, startDay: data.cycleStartDay),
        today: setupNow,
      );

      // 14,600 held - 6,000 bills - 2,000 savings = 6,600, over 22 days left.
      expect(limit.spendable, Money.taka(6600));
      expect(limit.daysLeft, 22);
      expect(limit.dailyLimit, Money.taka(300));
    });
  });

  test('expected income and bills are never counted as money held', () {
    final data = sampleSetup().copyWith(balances: const []);
    final records = SetupRecords.from(data, now: setupNow);

    expect(records.expectedIncome, isNotEmpty);
    expect(records.bills, isNotEmpty);
    expect(records.moneyHeld, Money.zero);
  });

  test('a cycle that starts on the 5th puts early days in the next month', () {
    // Today is 10 Oct, so the cycle runs 5 Oct to 4 Nov.
    final data = SetupData(
      displayName: 'Ashraf',
      cycleStartDay: 5,
      incomes: [
        _income('d3', 'Day 3', 3), //   3 Nov (next month, still to come)
        _income('d5', 'Day 5', 5), //   5 Oct (already passed)
        _income('d8', 'Day 8', 8), //   8 Oct (already passed)
        _income('d10', 'Day 10', 10), // 10 Oct (today counts as still to come)
        _income('d12', 'Day 12', 12), // 12 Oct
      ],
      fixedExpenses: [
        _bill('b3', 'Early bill', 3), // 3 Nov
        _bill('b8', 'Late bill', 8), //  8 Oct (unpaid and past: overdue)
      ],
    );
    final records = SetupRecords.from(data, now: setupNow);

    expect(
      records.expectedIncome.map((i) => i.id),
      ['setup-income-d3', 'setup-income-d10', 'setup-income-d12'],
    );
    expect(
      records.expectedIncome.map((i) => i.expectedOn),
      [DateTime(2026, 11, 3), DateTime(2026, 10, 10), DateTime(2026, 10, 12)],
    );
    expect(records.alreadyDueIncome, ['Day 5', 'Day 8']);

    expect(records.bills.map((b) => b.dueDate), [
      DateTime(2026, 11, 3),
      DateTime(2026, 10, 8),
    ]);

    // The unpaid bill from 8 Oct shows up as overdue on the calendar.
    final events = CalendarEvents.build(
      debts: [],
      bills: records.bills,
      expectedIncome: [],
    );
    final late = events.firstWhere((e) => e.title == 'Late bill');
    expect(late.isOverdueOn(setupNow), isTrue);
  });

  test('a cycle that crosses the new year works', () {
    // 20 Dec 2026, cycle starting on the 15th: 15 Dec to 14 Jan.
    final now = DateTime(2026, 12, 20, 9, 0);
    final data = SetupData(
      displayName: 'Ashraf',
      cycleStartDay: 15,
      incomes: [_income('d3', 'Day 3', 3)], // 3 Jan 2027
      fixedExpenses: [_bill('b20', 'Mid bill', 20)], // 20 Dec
    );
    final records = SetupRecords.from(data, now: now);

    expect(records.expectedIncome.single.expectedOn, DateTime(2027, 1, 3));
    expect(records.bills.single.dueDate, DateTime(2026, 12, 20));
  });

  test('weekly and yearly items and items without a day create nothing yet', () {
    final data = SetupData(
      displayName: 'Ashraf',
      incomes: [
        _income('w', 'Weekly job', 15, frequency: SetupFrequency.weekly),
        IncomeEntry(id: 'nd', name: 'No day', amount: Money.taka(100)),
      ],
      fixedExpenses: [
        _bill('fw', 'Weekly thing', null, frequency: SetupFrequency.weekly),
        _bill('fy', 'Yearly thing', 15, frequency: SetupFrequency.yearly),
        _bill('fnd', 'No day bill', null),
      ],
    );
    final records = SetupRecords.from(data, now: setupNow);

    expect(records.expectedIncome, isEmpty);
    expect(records.bills, isEmpty);
    expect(records.alreadyDueIncome, isEmpty);
  });

  test('a bill marked paid creates no bill, whatever its day', () {
    final data = SetupData(
      displayName: 'Ashraf',
      fixedExpenses: [_bill('b', 'Paid bill', 20, paid: true)],
    );

    expect(SetupRecords.from(data, now: setupNow).bills, isEmpty);
  });
}