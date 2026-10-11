import 'package:milbeki_app/core/utils/money.dart';

// The steps of the setup wizard, in order.
// An enum can carry a label, so screens never repeat label text.
enum SetupStep {
  preferences('About you'),
  income('Income'),
  fixedExpenses('Fixed expenses'),
  spending('Spending plan'),
  savings('Savings'),
  balances('Accounts'),
  review('Review');

  const SetupStep(this.label);
  final String label;
}

enum SetupFrequency {
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  const SetupFrequency(this.label);
  final String label;
}

enum FixedExpenseKind {
  rent('House rent'),
  electricity('Electricity'),
  gas('Gas'),
  water('Water'),
  internet('Internet'),
  mobile('Mobile'),
  education('Education'),
  other('Other');

  const FixedExpenseKind(this.label);
  final String label;
}

enum SpendingCategory {
  food('Food and groceries'),
  snacks('Snacks'),
  transport('Transportation'),
  shopping('Shopping'),
  entertainment('Entertainment'),
  health('Health'),
  education('Education'),
  other('Other personal');

  const SpendingCategory(this.label);
  final String label;
}

enum SetupAccountType {
  cash('Cash'),
  bkash('bKash'),
  nagad('Nagad'),
  bank('Bank'),
  other('Other');

  const SetupAccountType(this.label);
  final String label;
}

class SetupLimits {
  const SetupLimits._();

  /// The largest amount accepted anywhere in the wizard: ৳99,999,999.99.
  static const Money maxAmount = Money(9999999999);

  /// Every month has days 1 to 28, so a "day of the month" in this range
  /// falls on exactly one date in any budget cycle.
  static const int maxDayOfMonth = 28;
}

// One source of income, such as a family allowance or tutoring.
class IncomeEntry {
  const IncomeEntry({
    required this.id,
    required this.name,
    required this.amount,
    this.frequency = SetupFrequency.monthly,
    this.dayOfMonth,
    this.note,
  });

  final String id;
  final String name;
  final Money amount;
  final SetupFrequency frequency;

  /// The day of the month it usually arrives (1 to 28). Optional.
  final int? dayOfMonth;
  final String? note;
}

// A recurring commitment such as rent or internet.
class FixedExpenseEntry {
  const FixedExpenseEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.amount,
    this.frequency = SetupFrequency.monthly,
    this.dayOfMonth,
    this.paidThisCycle = false,
  });

  final String id;
  final FixedExpenseKind kind;
  final String title;
  final Money amount;
  final SetupFrequency frequency;

  /// The day of the month it is due (1 to 28). Required for monthly bills.
  final int? dayOfMonth;

  /// Already paid before using the app, so the money is already out of the
  /// opening balances. It creates no bill and no expense.
  final bool paidThisCycle;
}

class SavingsPlan {
  const SavingsPlan({
    this.monthlyTarget = Money.zero,
    this.purpose,
    this.targetDate,
  });

  final Money monthlyTarget;
  final String? purpose;
  final DateTime? targetDate;
}

// An account's starting balance. This is NOT income: it is money you already
// had, so it is stored as the account's opening balance only.
class OpeningBalance {
  const OpeningBalance({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
  });

  final String id;
  final String name;
  final SetupAccountType type;
  final Money amount;
}

// Everything the wizard collects. Treat the lists and the map as read-only:
// to change something, build a new SetupData with copyWith.
class SetupData {
  const SetupData({
    this.displayName = '',
    this.currencyCode = 'BDT',
    this.cycleStartDay = 1,
    this.incomes = const [],
    this.fixedExpenses = const [],
    this.spending = const {},
    this.savings = const SavingsPlan(),
    this.balances = const [],
  });

  final String displayName;
  final String currencyCode;
  final int cycleStartDay;
  final List<IncomeEntry> incomes;
  final List<FixedExpenseEntry> fixedExpenses;
  final Map<SpendingCategory, Money> spending;
  final SavingsPlan savings;
  final List<OpeningBalance> balances;

  SetupData copyWith({
    String? displayName,
    String? currencyCode,
    int? cycleStartDay,
    List<IncomeEntry>? incomes,
    List<FixedExpenseEntry>? fixedExpenses,
    Map<SpendingCategory, Money>? spending,
    SavingsPlan? savings,
    List<OpeningBalance>? balances,
  }) {
    return SetupData(
      displayName: displayName ?? this.displayName,
      currencyCode: currencyCode ?? this.currencyCode,
      cycleStartDay: cycleStartDay ?? this.cycleStartDay,
      incomes: incomes ?? this.incomes,
      fixedExpenses: fixedExpenses ?? this.fixedExpenses,
      spending: spending ?? this.spending,
      savings: savings ?? this.savings,
      balances: balances ?? this.balances,
    );
  }
}