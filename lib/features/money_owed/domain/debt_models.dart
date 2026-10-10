import 'package:milbeki_app/core/utils/date_only.dart';
import 'package:milbeki_app/core/utils/money.dart';

enum DebtDirection {
  youOwe, // you must pay someone back
  owedToYou, // someone must pay you back
}

enum DebtStatus { pending, partiallyPaid, paid, overdue, cancelled }

// One payment towards a debt. Payments are never edited or erased.
class DebtPayment {
  const DebtPayment({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.reference,
    this.note,
  });

  final String id;
  final Money amount;
  final DateTime paidAt;
  final String? reference;
  final String? note;
}

class Debt {
  const Debt({
    required this.id,
    required this.personName,
    required this.direction,
    required this.originalAmount,
    required this.startDate,
    required this.dueDate,
    this.description,
    this.cancelledAt,
    this.payments = const [],
  });

  final String id;
  final String personName;
  final DebtDirection direction;
  final Money originalAmount;
  final DateTime startDate;
  final DateTime dueDate;
  final String? description;

  /// Set when the debt is cancelled (for example, forgiven). Null otherwise.
  final DateTime? cancelledAt;
  final List<DebtPayment> payments;

  // Nothing below is stored. It is all calculated from the fields above,
  // so a debt can never say "paid" while still showing an unpaid balance.

  Money get paidAmount =>
      payments.fold<Money>(Money.zero, (sum, p) => sum + p.amount);

  Money get outstanding => originalAmount - paidAmount;

  bool get isCancelled => cancelledAt != null;

  /// Still open: not cancelled, and money is still owed.
  bool get isActive => !isCancelled && outstanding.paisa > 0;

  /// The status on a given day. The checks run in order, and the first match wins.
  DebtStatus statusOn(DateTime today) {
    if (isCancelled) return DebtStatus.cancelled;
    if (outstanding.paisa <= 0) return DebtStatus.paid;
    // Due today is not overdue. Overdue starts the next day.
    if (dueDate.dateOnly.isBefore(today.dateOnly)) return DebtStatus.overdue;
    if (payments.isNotEmpty) return DebtStatus.partiallyPaid;
    return DebtStatus.pending;
  }

  /// Returns a NEW debt with the payment added. This debt is left unchanged.
  /// A payment whose id already exists is ignored (a retry, not a second payment).
  Debt withPayment(DebtPayment payment) {
    if (payments.any((p) => p.id == payment.id)) return this;

    return Debt(
      id: id,
      personName: personName,
      direction: direction,
      originalAmount: originalAmount,
      startDate: startDate,
      dueDate: dueDate,
      description: description,
      cancelledAt: cancelledAt,
      payments: [...payments, payment],
    );
  }
}