import 'package:milbeki_app/core/utils/budget_cycle.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/dashboard/domain/dashboard_models.dart';
import 'package:milbeki_app/features/money_owed/data/mock_debt_data.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_rules.dart';

// Fixed sample data, so the dashboard looks the same every time while we
// build the screens. "Today" is fixed on purpose. The server replaces this later.
class MockDashboardData {
  static DashboardData sample() {
    final now = DateTime(2026, 10, 10, 15, 30);

    return DashboardData(
      userName: 'Ashraf',
      now: now,
      cycle: BudgetCycle.containing(now, startDay: 1),
      moneyHeld: Money.taka(14600), // Cash 2,600 + bKash 12,000
      periodIncome: Money.taka(10000),
      periodExpenses: Money.taka(500),
      monthlyBudget: Money.taka(8000),
      savingsRemaining: Money.taka(2000),
      categories: [
        CategorySpend(
          name: 'Food',
          spent: Money.taka(240),
          budget: Money.taka(3000),
        ),
        CategorySpend(
          name: 'Transport',
          spent: Money.taka(100),
          budget: Money.taka(120),
        ),
        CategorySpend(
          name: 'Snacks',
          spent: Money.taka(60),
          budget: Money.taka(100),
        ),
        CategorySpend(
          name: 'Shopping',
          spent: Money.taka(100),
          budget: Money.taka(1500),
        ),
      ],
      todayExpenses: [
        TodayExpense(
          title: 'Lunch',
          categoryName: 'Food',
          amount: Money.taka(180),
          time: DateTime(2026, 10, 10, 13, 10),
        ),
        TodayExpense(
          title: 'Bus fare',
          categoryName: 'Transport',
          amount: Money.taka(40),
          time: DateTime(2026, 10, 10, 9, 0),
        ),
        TodayExpense(
          title: 'Breakfast',
          categoryName: 'Food',
          amount: Money.taka(60),
          time: DateTime(2026, 10, 10, 8, 15),
        ),
      ],
      dueItems: [
        DueItem(
          title: 'House rent',
          amount: Money.taka(5000),
          dueDate: DateTime(2026, 10, 15),
          kind: DueKind.bill,
        ),
        DueItem(
          title: 'Internet',
          amount: Money.taka(1000),
          dueDate: DateTime(2026, 10, 20),
          kind: DueKind.bill,
        ),
        // Due after the cycle ends on 31 Oct, so it is not reserved yet.
        DueItem(
          title: 'Mobile bill',
          amount: Money.taka(400),
          dueDate: DateTime(2026, 11, 3),
          kind: DueKind.bill,
        ),
        // Debt rows come from the debt records, so the two screens can't disagree.
        ...DebtRules.toDueItems(MockDebtData.sample()),
      ],
    );
  }
}