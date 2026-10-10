import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/date_only.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';

final _today = DateTime(2026, 10, 10, 15, 30);

DebtPayment _pay(String id, int taka) => DebtPayment(
      id: id,
      amount: Money.taka(taka),
      paidAt: DateTime(2026, 10, 2, 10, 0),
    );

Debt _debt({
  int original = 1000,
  DateTime? due,
  List<DebtPayment> payments = const [],
  DateTime? cancelledAt,
}) =>
    Debt(
      id: 'd1',
      personName: 'Fatir',
      direction: DebtDirection.youOwe,
      originalAmount: Money.taka(original),
      startDate: DateTime(2026, 9, 25),
      dueDate: due ?? DateTime(2026, 10, 20),
      payments: payments,
      cancelledAt: cancelledAt,
    );

void main() {
  test('dateOnly drops the time of day', () {
    expect(DateTime(2026, 10, 10, 23, 59).dateOnly, DateTime(2026, 10, 10));
  });

  group('outstanding amount', () {
    test('Phase 1 example: 1,000 minus 300 and 200 leaves 500', () {
      final debt = _debt(payments: [_pay('p1', 300), _pay('p2', 200)]);
      expect(debt.paidAmount, Money.taka(500));
      expect(debt.outstanding, Money.taka(500));
    });

    test('no payments: the whole amount is outstanding', () {
      expect(_debt().outstanding, Money.taka(1000));
    });

    test('payments in paisa add up exactly', () {
      final debt = Debt(
        id: 'd2',
        personName: 'Rahim',
        direction: DebtDirection.owedToYou,
        originalAmount: Money.parse('100.00'),
        startDate: DateTime(2026, 9, 25),
        dueDate: DateTime(2026, 10, 20),
        payments: [
          DebtPayment(
            id: 'a',
            amount: Money.parse('33.33'),
            paidAt: DateTime(2026, 10, 2),
          ),
          DebtPayment(
            id: 'b',
            amount: Money.parse('33.33'),
            paidAt: DateTime(2026, 10, 3),
          ),
        ],
      );
      expect(debt.outstanding, Money.parse('33.34'));
    });
  });

  group('status', () {
    test('no payments and not yet due is pending', () {
      expect(_debt().statusOn(_today), DebtStatus.pending);
    });

    test('some payments and not yet due is partially paid', () {
      final debt = _debt(payments: [_pay('p1', 100)]);
      expect(debt.statusOn(_today), DebtStatus.partiallyPaid);
    });

    test('fully paid is paid, even when the due date has passed', () {
      final debt = _debt(
        original: 500,
        due: DateTime(2026, 10, 1),
        payments: [_pay('p1', 500)],
      );
      expect(debt.statusOn(_today), DebtStatus.paid);
      expect(debt.isActive, isFalse);
    });

    test('past the due date with a balance is overdue', () {
      final debt = _debt(due: DateTime(2026, 10, 9));
      expect(debt.statusOn(_today), DebtStatus.overdue);
    });

    test('due today is not overdue, whatever the time of day', () {
      expect(
        _debt(due: DateTime(2026, 10, 10)).statusOn(_today),
        DebtStatus.pending,
      );
      expect(
        _debt(due: DateTime(2026, 10, 10, 23, 59)).statusOn(_today),
        DebtStatus.pending,
      );
    });

    test('overdue beats partially paid', () {
      final debt = _debt(
        due: DateTime(2026, 10, 1),
        payments: [_pay('p1', 100)],
      );
      expect(debt.statusOn(_today), DebtStatus.overdue);
    });

    test('cancelled beats every other status', () {
      final debt = _debt(
        due: DateTime(2026, 10, 1),
        payments: [_pay('p1', 100)],
        cancelledAt: DateTime(2026, 10, 6),
      );
      expect(debt.statusOn(_today), DebtStatus.cancelled);
      expect(debt.isActive, isFalse);
    });
  });

  group('withPayment', () {
    test('returns a new debt and leaves the original unchanged', () {
      final original = _debt();
      final updated = original.withPayment(_pay('p1', 300));

      expect(original.payments, isEmpty);
      expect(original.outstanding, Money.taka(1000));
      expect(updated.payments.length, 1);
      expect(updated.outstanding, Money.taka(700));
    });

    test('a payment with an existing id is ignored', () {
      final once = _debt().withPayment(_pay('p1', 300));
      final twice = once.withPayment(_pay('p1', 300));

      expect(twice.payments.length, 1);
      expect(twice.outstanding, Money.taka(700));
    });
  });
}