import 'package:milbeki_app/core/utils/money.dart';

// A bill due on a specific day, such as this month's rent. A recurring RULE
// ("rent, monthly") will create one of these each month (Phase 9).
// An unpaid bill is only a promise to pay. It is NOT an expense until it is
// paid and becomes a real transaction.
class BillInstance {
  const BillInstance({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.paidAt,
    this.skippedAt,
  });

  final String id;
  final String title;
  final Money amount;
  final DateTime dueDate;
  final DateTime? paidAt;
  final DateTime? skippedAt;

  /// Still waiting: not paid and not skipped.
  bool get isOpen => paidAt == null && skippedAt == null;

  /// Returns a NEW bill marked as paid. Marking twice keeps the first payment.
  BillInstance markPaid(DateTime at) {
    if (!isOpen) return this;
    return BillInstance(
      id: id,
      title: title,
      amount: amount,
      dueDate: dueDate,
      paidAt: at,
      skippedAt: skippedAt,
    );
  }
}

// Income you expect but have not received. It is not in any account yet, so it
// never counts towards your balance or your income totals.
class ExpectedIncome {
  const ExpectedIncome({
    required this.id,
    required this.sourceName,
    required this.amount,
    required this.expectedOn,
    this.receivedAt,
  });

  final String id;
  final String sourceName;
  final Money amount;
  final DateTime expectedOn;
  final DateTime? receivedAt;

  bool get isOpen => receivedAt == null;

  /// Returns a NEW record marked as received. Marking twice keeps the first time.
  ExpectedIncome markReceived(DateTime at) {
    if (!isOpen) return this;
    return ExpectedIncome(
      id: id,
      sourceName: sourceName,
      amount: amount,
      expectedOn: expectedOn,
      receivedAt: at,
    );
  }
}