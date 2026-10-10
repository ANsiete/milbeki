import 'package:milbeki_app/core/utils/budget_cycle.dart';
import 'package:milbeki_app/core/utils/money.dart';

// What kind of upcoming item this is. It decides how the item is counted.
enum DueKind {
  bill, // rent, internet... money you must pay
  debtYouOwe, // money you must pay back to someone
  owedToYou, // money someone promised to pay you (NOT in your pocket yet)
}

class DueItem {
  const DueItem({
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.kind,
  });

  final String title;

  /// The amount still unpaid.
  final Money amount;
  final DateTime dueDate;
  final DueKind kind;
}

class CategorySpend {
  const CategorySpend({
    required this.name,
    required this.spent,
    required this.budget,
  });

  final String name;
  final Money spent;
  final Money budget;
}

class TodayExpense {
  const TodayExpense({
    required this.title,
    required this.categoryName,
    required this.amount,
    required this.time,
  });

  final String title;
  final String categoryName;
  final Money amount;
  final DateTime time;
}

// Everything the Home dashboard needs. For now it comes from sample data;
// later the server will send the same information.
class DashboardData {
  const DashboardData({
    required this.userName,
    required this.now,
    required this.cycle,
    required this.moneyHeld,
    required this.periodIncome,
    required this.periodExpenses,
    required this.monthlyBudget,
    required this.savingsRemaining,
    required this.categories,
    required this.todayExpenses,
    required this.dueItems,
  });

  final String userName;
  final DateTime now;
  final BudgetCycle cycle;

  /// Real money in all accounts right now.
  final Money moneyHeld;

  /// Income actually received, and expenses actually paid, this cycle.
  final Money periodIncome;
  final Money periodExpenses;

  final Money monthlyBudget;

  /// Savings target minus what is already saved this cycle.
  final Money savingsRemaining;

  final List<CategorySpend> categories;
  final List<TodayExpense> todayExpenses;
  final List<DueItem> dueItems;

  /// Calculated from the list, never stored separately.
  Money get spentToday =>
      todayExpenses.fold<Money>(Money.zero, (sum, e) => sum + e.amount);
}