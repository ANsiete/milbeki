import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/setup/domain/setup_models.dart';

/// Turns an amount into an approximate monthly amount.
/// Weekly: times 52, divided by 12. Yearly: divided by 12.
/// The result is rounded DOWN to the paisa, so estimates never overstate income.
Money monthlyEquivalent(Money amount, SetupFrequency frequency) {
  return switch (frequency) {
    SetupFrequency.monthly => amount,
    // ~/ is integer division: it drops the fraction.
    SetupFrequency.weekly => Money((amount.paisa * 52) ~/ 12),
    SetupFrequency.yearly => Money(amount.paisa ~/ 12),
  };
}

// The figures on the review step. Every figure except [moneyHeld] is an
// ESTIMATE, not a confirmed transaction.
class SetupOverview {
  const SetupOverview({
    required this.expectedMonthlyIncome,
    required this.fixedExpenses,
    required this.fixedStillToPay,
    required this.variableExpenses,
    required this.savingsTarget,
    required this.estimatedRemaining,
    required this.moneyHeld,
  });

  /// All income sources, converted to a monthly estimate.
  final Money expectedMonthlyIncome;

  /// All fixed expenses, converted to a monthly estimate.
  final Money fixedExpenses;

  /// The part of the fixed expenses not marked as paid yet.
  final Money fixedStillToPay;

  /// The total of the regular spending estimates.
  final Money variableExpenses;

  final Money savingsTarget;

  /// Income - fixed - variable - savings. Can be negative.
  final Money estimatedRemaining;

  /// Opening balances added together. This is money you already have: it is
  /// NOT income, and it is NOT part of [estimatedRemaining].
  final Money moneyHeld;

  bool get isShortfall => estimatedRemaining.isNegative;

  /// How much short you are, or zero.
  Money get shortfall =>
      isShortfall ? Money(-estimatedRemaining.paisa) : Money.zero;

  factory SetupOverview.of(SetupData data) {
    final income = data.incomes.fold<Money>(
      Money.zero,
      (sum, e) => sum + monthlyEquivalent(e.amount, e.frequency),
    );
    final fixed = data.fixedExpenses.fold<Money>(
      Money.zero,
      (sum, e) => sum + monthlyEquivalent(e.amount, e.frequency),
    );
    final stillToPay = data.fixedExpenses
        .where((e) => !e.paidThisCycle)
        .fold<Money>(
          Money.zero,
          (sum, e) => sum + monthlyEquivalent(e.amount, e.frequency),
        );
    final variable =
        data.spending.values.fold<Money>(Money.zero, (sum, a) => sum + a);
    final savings = data.savings.monthlyTarget;
    final held =
        data.balances.fold<Money>(Money.zero, (sum, b) => sum + b.amount);

    return SetupOverview(
      expectedMonthlyIncome: income,
      fixedExpenses: fixed,
      fixedStillToPay: stillToPay,
      variableExpenses: variable,
      savingsTarget: savings,
      estimatedRemaining: income - fixed - variable - savings,
      moneyHeld: held,
    );
  }
}