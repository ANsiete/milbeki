import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/setup/domain/setup_models.dart';

// "Now" for the setup tests: Saturday 10 Oct 2026, the same day as the sample app.
final DateTime setupNow = DateTime(2026, 10, 10, 15, 30);

// A complete, valid setup, with worked numbers:
//   Income:   10,000 + 4,000                      = 14,000 a month
//   Fixed:    5,000 + 1,000 + 650 (already paid)  = 6,650 a month
//   Variable: 3,000 + 120 + 100 + 1,500           = 4,720 a month
//   Savings:  2,000
//   Remaining: 14,000 - 6,650 - 4,720 - 2,000     = 630
//   Money held: 2,600 + 12,000                    = 14,600
SetupData sampleSetup() {
  return SetupData(
    displayName: 'Ashraf',
    cycleStartDay: 1,
    incomes: [
      IncomeEntry(
        id: 'inc-allowance',
        name: 'Family allowance',
        amount: Money.taka(10000),
        dayOfMonth: 1,
      ),
      IncomeEntry(
        id: 'inc-tutoring',
        name: 'Tutoring',
        amount: Money.taka(4000),
        dayOfMonth: 25,
      ),
    ],
    fixedExpenses: [
      FixedExpenseEntry(
        id: 'fx-rent',
        kind: FixedExpenseKind.rent,
        title: 'House rent',
        amount: Money.taka(5000),
        dayOfMonth: 15,
      ),
      FixedExpenseEntry(
        id: 'fx-internet',
        kind: FixedExpenseKind.internet,
        title: 'Internet',
        amount: Money.taka(1000),
        dayOfMonth: 20,
      ),
      FixedExpenseEntry(
        id: 'fx-elec',
        kind: FixedExpenseKind.electricity,
        title: 'Electricity',
        amount: Money.taka(650),
        dayOfMonth: 5,
        paidThisCycle: true,
      ),
    ],
    spending: {
      SpendingCategory.food: Money.taka(3000),
      SpendingCategory.transport: Money.taka(120),
      SpendingCategory.snacks: Money.taka(100),
      SpendingCategory.shopping: Money.taka(1500),
    },
    savings: SavingsPlan(
      monthlyTarget: Money.taka(2000),
      purpose: 'Laptop',
      targetDate: DateTime(2026, 12, 31),
    ),
    balances: [
      OpeningBalance(
        id: 'acc-cash',
        name: 'Cash',
        type: SetupAccountType.cash,
        amount: Money.taka(2600),
      ),
      OpeningBalance(
        id: 'acc-bkash',
        name: 'bKash',
        type: SetupAccountType.bkash,
        amount: Money.taka(12000),
      ),
    ],
  );
}