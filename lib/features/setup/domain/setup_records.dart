import 'package:milbeki_app/core/utils/budget_cycle.dart';
import 'package:milbeki_app/core/utils/date_only.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/calendar/domain/calendar_sources.dart';
import 'package:milbeki_app/features/setup/domain/setup_models.dart';

// What finishing the wizard would create.
//
// There is deliberately NO income transaction and NO expense transaction in
// here. Opening balances are starting balances, not income. Bills and expected
// income are promises that are still OPEN: nothing is paid or received.
class SetupRecords {
  const SetupRecords({
    required this.accounts,
    required this.expectedIncome,
    required this.bills,
    required this.alreadyDueIncome,
  });

  /// The accounts, each with its opening balance.
  final List<OpeningBalance> accounts;

  /// Income still to come this cycle (all of it still open).
  final List<ExpectedIncome> expectedIncome;

  /// Unpaid monthly bills this cycle (all of them still open).
  final List<BillInstance> bills;

  /// Monthly income whose day this cycle has already passed. Nothing is
  /// created for it: it is assumed to be in your opening balances.
  final List<String> alreadyDueIncome;

  /// Real money in the accounts. Expected income and bills are not part of it.
  Money get moneyHeld =>
      accounts.fold<Money>(Money.zero, (sum, a) => sum + a.amount);

  /// Assumes the data has already passed SetupValidator.
  factory SetupRecords.from(SetupData data, {required DateTime now}) {
    final cycle = BudgetCycle.containing(now, startDay: data.cycleStartDay);
    final today = now.dateOnly;

    final expected = <ExpectedIncome>[];
    final alreadyDue = <String>[];
    for (final entry in data.incomes) {
      final day = entry.dayOfMonth;
      // Weekly and yearly income, and income without a day, wait for the
      // recurring-rules work in Phase 9.
      if (entry.frequency != SetupFrequency.monthly || day == null) continue;

      final date = _dateInCycle(cycle, day);
      if (date.isBefore(today)) {
        alreadyDue.add(entry.name.trim());
        continue;
      }
      expected.add(
        ExpectedIncome(
          id: 'setup-income-${entry.id}',
          sourceName: entry.name.trim(),
          amount: entry.amount,
          expectedOn: date,
        ),
      );
    }

    final bills = <BillInstance>[];
    for (final item in data.fixedExpenses) {
      final day = item.dayOfMonth;
      // A bill marked paid is already out of the opening balances, so it
      // creates nothing. Weekly and yearly bills wait for Phase 9.
      if (item.paidThisCycle || item.frequency != SetupFrequency.monthly) {
        continue;
      }
      if (day == null) continue;

      bills.add(
        BillInstance(
          id: 'setup-bill-${item.id}',
          title: item.title.trim(),
          amount: item.amount,
          // An unpaid bill whose day has passed is created as overdue.
          dueDate: _dateInCycle(cycle, day),
        ),
      );
    }

    return SetupRecords(
      accounts: List.unmodifiable(data.balances),
      expectedIncome: List.unmodifiable(expected),
      bills: List.unmodifiable(bills),
      alreadyDueIncome: List.unmodifiable(alreadyDue),
    );
  }
}

// A cycle covers exactly one month, and days 1 to 28 exist in every month, so
// a day of the month falls on exactly one date in the cycle.
//   Cycle 5 Oct to 4 Nov: day 20 is 20 Oct, and day 3 is 3 Nov.
DateTime _dateInCycle(BudgetCycle cycle, int day) {
  final inStartMonth = DateTime(cycle.start.year, cycle.start.month, day);
  if (!inStartMonth.isBefore(cycle.start)) return inStartMonth;
  // DateTime fixes overflow itself: month 13 means January of the next year.
  return DateTime(cycle.start.year, cycle.start.month + 1, day);
}