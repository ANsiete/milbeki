import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';

// Fixed sample debts, matching the worked example above. "Today" in the sample
// app is 10 Oct 2026. The server provides real debts in a later phase.
class MockDebtData {
  static List<Debt> sample() {
    return [
      Debt(
        id: 'debt-fatir',
        personName: 'Fatir',
        direction: DebtDirection.youOwe,
        originalAmount: Money.taka(500),
        startDate: DateTime(2026, 9, 25),
        dueDate: DateTime(2026, 10, 20),
        description: 'Borrowed for textbooks',
        payments: [
          DebtPayment(
            id: 'pay-fatir-1',
            amount: Money.taka(200),
            paidAt: DateTime(2026, 10, 2, 10, 0),
            note: 'Paid by bKash',
          ),
        ],
      ),
      Debt(
        id: 'debt-rahim',
        personName: 'Rahim',
        direction: DebtDirection.owedToYou,
        originalAmount: Money.taka(300),
        startDate: DateTime(2026, 9, 28),
        dueDate: DateTime(2026, 10, 15),
        description: 'Lent for lunch and bus fare',
        payments: [
          DebtPayment(
            id: 'pay-rahim-1',
            amount: Money.taka(100),
            paidAt: DateTime(2026, 10, 5, 18, 30),
          ),
        ],
      ),
      Debt(
        id: 'debt-sabbir',
        personName: 'Sabbir',
        direction: DebtDirection.owedToYou,
        originalAmount: Money.taka(1000),
        startDate: DateTime(2026, 8, 20),
        dueDate: DateTime(2026, 10, 1), // already passed: overdue
        description: 'Lent for an exam fee',
      ),
      Debt(
        id: 'debt-mitu',
        personName: 'Mitu',
        direction: DebtDirection.youOwe,
        originalAmount: Money.taka(1500),
        startDate: DateTime(2026, 8, 10),
        dueDate: DateTime(2026, 9, 30),
        description: 'Shared a group order',
        payments: [
          DebtPayment(
            id: 'pay-mitu-1',
            amount: Money.taka(1000),
            paidAt: DateTime(2026, 9, 15, 12, 0),
          ),
          DebtPayment(
            id: 'pay-mitu-2',
            amount: Money.taka(500),
            paidAt: DateTime(2026, 9, 29, 20, 15),
          ),
        ],
      ),
      Debt(
        id: 'debt-karim',
        personName: 'Karim',
        direction: DebtDirection.owedToYou,
        originalAmount: Money.taka(800),
        startDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 10, 5),
        description: 'Forgiven',
        cancelledAt: DateTime(2026, 10, 6, 9, 0),
      ),
    ];
  }
}