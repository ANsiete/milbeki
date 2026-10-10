import 'package:milbeki_app/core/utils/date_only.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/dashboard/domain/dashboard_models.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';

enum DebtSort { dueDate, amount }

// The totals shown at the top of the Money Owed screen.
// These are GROSS figures. "You owe" and "Owed to you" are never subtracted
// from each other, because a receivable is not money in your pocket.
class DebtSummary {
  const DebtSummary({
    required this.youOweTotal,
    required this.owedToYouTotal,
    required this.youOweOverdue,
    required this.owedToYouOverdue,
    required this.dueSoon,
    required this.partiallySettledCount,
  });

  final Money youOweTotal;
  final Money owedToYouTotal;
  final Money youOweOverdue;
  final Money owedToYouOverdue;

  /// Open debts due from today to [soonDays] days ahead, earliest first.
  final List<Debt> dueSoon;

  /// Open debts that have received at least one payment.
  final int partiallySettledCount;

  factory DebtSummary.of(
    List<Debt> debts, {
    required DateTime today,
    int soonDays = 7,
  }) {
    var youOwe = Money.zero;
    var owedToYou = Money.zero;
    var youOweOverdue = Money.zero;
    var owedToYouOverdue = Money.zero;
    var partial = 0;
    final soon = <Debt>[];

    final todayDay = today.dateOnly;
    final soonEnd =
        DateTime(todayDay.year, todayDay.month, todayDay.day + soonDays);

    for (final debt in debts) {
      // Cancelled and fully paid debts count for nothing.
      if (!debt.isActive) continue;

      final isOverdue = debt.statusOn(today) == DebtStatus.overdue;

      if (debt.direction == DebtDirection.youOwe) {
        youOwe += debt.outstanding;
        if (isOverdue) youOweOverdue += debt.outstanding;
      } else {
        owedToYou += debt.outstanding;
        if (isOverdue) owedToYouOverdue += debt.outstanding;
      }

      if (debt.payments.isNotEmpty) partial++;

      final due = debt.dueDate.dateOnly;
      if (!due.isBefore(todayDay) && !due.isAfter(soonEnd)) soon.add(debt);
    }

    soon.sort(DebtRules._byDueDate);

    return DebtSummary(
      youOweTotal: youOwe,
      owedToYouTotal: owedToYou,
      youOweOverdue: youOweOverdue,
      owedToYouOverdue: owedToYouOverdue,
      dueSoon: soon,
      partiallySettledCount: partial,
    );
  }
}

class DebtRules {
  /// Returns an error message, or null when the payment is allowed.
  /// The server repeats these checks later. This gives instant feedback.
  static String? validatePayment({
    required Debt debt,
    required Money amount,
    required DateTime paidAt,
    required DateTime now,
  }) {
    if (debt.isCancelled) return 'This debt was cancelled';
    if (debt.outstanding.paisa <= 0) return 'This debt is already fully paid';
    if (amount.paisa <= 0) return 'Payment must be greater than 0';
    if (amount.paisa > debt.outstanding.paisa) {
      return 'Payment cannot be more than the outstanding '
          '${debt.outstanding.format()}';
    }
    // One minute of margin, in case the clock moved while the form was open.
    if (paidAt.isAfter(now.add(const Duration(minutes: 1)))) {
      return 'A payment cannot be in the future';
    }
    if (paidAt.dateOnly.isBefore(debt.startDate.dateOnly)) {
      return 'A payment cannot be dated before the debt began';
    }
    return null;
  }

  /// Search by name, filter by direction or status, then sort.
  static List<Debt> filter(
    List<Debt> debts, {
    required DateTime today,
    DebtDirection? direction,
    DebtStatus? status,
    String search = '',
    DebtSort sort = DebtSort.dueDate,
  }) {
    final query = search.trim().toLowerCase();

    final result = debts.where((debt) {
      if (direction != null && debt.direction != direction) return false;
      if (status != null && debt.statusOn(today) != status) return false;
      if (query.isNotEmpty &&
          !debt.personName.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    result.sort(sort == DebtSort.dueDate ? _byDueDate : _byAmountDescending);
    return result;
  }

  /// The upcoming-items view of the open debts, for the dashboard (and later,
  /// the calendar). Built from the debt records, so nothing is stored twice.
  static List<DueItem> toDueItems(List<Debt> debts) {
    return [
      for (final debt in debts)
        if (debt.isActive)
          DueItem(
            title: debt.direction == DebtDirection.youOwe
                ? 'Repay ${debt.personName}'
                : '${debt.personName} will pay you',
            amount: debt.outstanding, // what is LEFT, not the original amount
            dueDate: debt.dueDate,
            kind: debt.direction == DebtDirection.youOwe
                ? DueKind.debtYouOwe
                : DueKind.owedToYou,
          ),
    ];
  }

  // Sorting: when two debts tie, fall back to name and then id, so the order
  // is always the same.
  static int _byDueDate(Debt a, Debt b) {
    final byDate = a.dueDate.compareTo(b.dueDate);
    if (byDate != 0) return byDate;
    final byName = a.personName.compareTo(b.personName);
    if (byName != 0) return byName;
    return a.id.compareTo(b.id);
  }

  static int _byAmountDescending(Debt a, Debt b) {
    final byAmount = b.outstanding.paisa.compareTo(a.outstanding.paisa);
    if (byAmount != 0) return byAmount;
    return _byDueDate(a, b);
  }
}