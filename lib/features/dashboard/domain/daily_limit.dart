import 'package:milbeki_app/core/utils/budget_cycle.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/dashboard/domain/dashboard_models.dart';

// The result of the daily-limit calculation, including every number used,
// so the screen can explain how the limit was reached.
class DailyLimit {
  const DailyLimit({
    required this.moneyHeld,
    required this.billsDue,
    required this.debtsDue,
    required this.savingsReserved,
    required this.spendable,
    required this.spentToday,
    required this.startOfDay,
    required this.daysLeft,
    required this.dailyLimit,
    required this.remainingToday,
  });

  final Money moneyHeld;
  final Money billsDue;
  final Money debtsDue;
  final Money savingsReserved;

  /// Money held, minus everything reserved. Can be negative.
  final Money spendable;

  final Money spentToday;

  /// Spendable money as it was when today began (spendable + spent today).
  final Money startOfDay;

  final int daysLeft;

  /// Never negative.
  final Money dailyLimit;

  /// Limit minus spent today. Negative means you are over today's limit.
  final Money remainingToday;

  /// True when your commitments are bigger than the money you hold.
  bool get isShortfall => spendable.isNegative;

  /// How much short you are, or zero.
  Money get shortfall => isShortfall ? Money(-spendable.paisa) : Money.zero;
}

class DailyLimitCalculator {
  static DailyLimit calculate({
    required Money moneyHeld,
    required List<DueItem> dueItems,
    required Money savingsRemaining,
    required Money spentToday,
    required BudgetCycle cycle,
    required DateTime today,
  }) {
    var bills = Money.zero;
    var debts = Money.zero;

    for (final item in dueItems) {
      // Compare dates only, so a bill due at 3 PM on the last day still counts.
      final dueDay = DateTime(
        item.dueDate.year,
        item.dueDate.month,
        item.dueDate.day,
      );
      // Due after this cycle ends: it belongs to the next cycle.
      if (dueDay.isAfter(cycle.end)) continue;

      // Overdue items pass the check above, because they are still unpaid.
      if (item.kind == DueKind.bill) {
        bills += item.amount;
      } else if (item.kind == DueKind.debtYouOwe) {
        debts += item.amount;
      }
      // DueKind.owedToYou is deliberately ignored: money others owe you is
      // not in your pocket, so it must never raise your spending limit.
    }

    // Saving more than the target must not raise the limit.
    final savings = savingsRemaining.isNegative ? Money.zero : savingsRemaining;

    final spendable = moneyHeld - bills - debts - savings;

    // Today is always inside the cycle, so this is at least 1.
    // The guard only protects against dividing by zero if that ever changes.
    final rawDays = cycle.daysLeftFrom(today);
    final daysLeft = rawDays < 1 ? 1 : rawDays;

    // Your balance already dropped when you spent today, so add today's
    // spending back before dividing. Otherwise it would be subtracted twice.
    final startOfDay = spendable + spentToday;

    Money dailyLimit;
    if (startOfDay.paisa <= 0) {
      dailyLimit = Money.zero;
    } else {
      // Integer division in paisa, then round DOWN to whole taka,
      // so the app never suggests spending more than you have.
      final perDayPaisa = startOfDay.paisa ~/ daysLeft;
      dailyLimit = Money((perDayPaisa ~/ 100) * 100);
    }

    return DailyLimit(
      moneyHeld: moneyHeld,
      billsDue: bills,
      debtsDue: debts,
      savingsReserved: savings,
      spendable: spendable,
      spentToday: spentToday,
      startOfDay: startOfDay,
      daysLeft: daysLeft,
      dailyLimit: dailyLimit,
      remainingToday: dailyLimit - spentToday,
    );
  }
}