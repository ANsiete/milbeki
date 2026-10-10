import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/dashboard/domain/dashboard_models.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_rules.dart';

final _today = DateTime(2026, 10, 10, 15, 30);

DebtPayment _pay(String id, int taka) => DebtPayment(
      id: id,
      amount: Money.taka(taka),
      paidAt: DateTime(2026, 10, 2, 10, 0),
    );

// Every test debt began on 1 Sep 2026.
Debt _d(
  String id,
  DebtDirection direction,
  int original,
  DateTime due, {
  String person = 'Someone',
  List<DebtPayment> payments = const [],
  DateTime? cancelledAt,
}) =>
    Debt(
      id: id,
      personName: person,
      direction: direction,
      originalAmount: Money.taka(original),
      startDate: DateTime(2026, 9, 1),
      dueDate: due,
      payments: payments,
      cancelledAt: cancelledAt,
    );

const _youOwe = DebtDirection.youOwe;
const _owedToYou = DebtDirection.owedToYou;

void main() {
  group('validatePayment', () {
    // 1,000 owed, 300 already paid, so 700 is outstanding.
    final debt = _d(
      'd1',
      _youOwe,
      1000,
      DateTime(2026, 10, 20),
      payments: [_pay('p1', 300)],
    );

    String? check(Money amount, [DateTime? paidAt]) =>
        DebtRules.validatePayment(
          debt: debt,
          amount: amount,
          paidAt: paidAt ?? _today,
          now: _today,
        );

    test('accepts a partial payment and the full outstanding amount', () {
      expect(check(Money.taka(200)), isNull);
      expect(check(Money.taka(700)), isNull);
    });

    test('rejects more than the outstanding amount', () {
      expect(
        check(Money.parse('700.01')),
        'Payment cannot be more than the outstanding ৳700',
      );
    });

    test('rejects zero and negative amounts', () {
      expect(check(Money.zero), 'Payment must be greater than 0');
      expect(check(Money.taka(-5)), 'Payment must be greater than 0');
    });

    test('rejects a payment in the future', () {
      expect(
        check(Money.taka(100), DateTime(2026, 10, 11)),
        'A payment cannot be in the future',
      );
    });

    test('rejects a payment dated before the debt began', () {
      expect(
        check(Money.taka(100), DateTime(2026, 8, 20)),
        'A payment cannot be dated before the debt began',
      );
    });

    test('accepts a payment on the day the debt began', () {
      expect(check(Money.taka(100), DateTime(2026, 9, 1, 8, 0)), isNull);
    });

    test('rejects a payment on a cancelled debt', () {
      final cancelled = _d(
        'd2',
        _youOwe,
        1000,
        DateTime(2026, 10, 20),
        cancelledAt: DateTime(2026, 10, 6),
      );
      expect(
        DebtRules.validatePayment(
          debt: cancelled,
          amount: Money.taka(100),
          paidAt: _today,
          now: _today,
        ),
        'This debt was cancelled',
      );
    });

    test('rejects a payment on a debt that is already paid', () {
      final paid = _d(
        'd3',
        _youOwe,
        500,
        DateTime(2026, 10, 20),
        payments: [_pay('p1', 500)],
      );
      expect(
        DebtRules.validatePayment(
          debt: paid,
          amount: Money.taka(1),
          paidAt: _today,
          now: _today,
        ),
        'This debt is already fully paid',
      );
    });
  });

  group('DebtSummary', () {
    test('cancelled and fully paid debts never count', () {
      final summary = DebtSummary.of(
        [
          _d('a', _youOwe, 500, DateTime(2026, 10, 20)),
          _d('b', _youOwe, 400, DateTime(2026, 10, 20),
              payments: [_pay('p', 400)]),
          _d('c', _owedToYou, 800, DateTime(2026, 10, 20),
              cancelledAt: DateTime(2026, 10, 6)),
        ],
        today: _today,
      );

      expect(summary.youOweTotal, Money.taka(500));
      expect(summary.owedToYouTotal, Money.zero);
    });

    test('totals use the outstanding amount, not the original', () {
      final summary = DebtSummary.of(
        [
          _d('a', _youOwe, 500, DateTime(2026, 10, 20),
              payments: [_pay('p', 200)]),
        ],
        today: _today,
      );
      expect(summary.youOweTotal, Money.taka(300));
    });

    test('overdue amounts are split by direction', () {
      final summary = DebtSummary.of(
        [
          _d('a', _youOwe, 400, DateTime(2026, 10, 1)),
          _d('b', _owedToYou, 250, DateTime(2026, 10, 5)),
          _d('c', _youOwe, 100, DateTime(2026, 10, 20)),
        ],
        today: _today,
      );

      expect(summary.youOweTotal, Money.taka(500));
      expect(summary.owedToYouTotal, Money.taka(250));
      expect(summary.youOweOverdue, Money.taka(400));
      expect(summary.owedToYouOverdue, Money.taka(250));
    });

    test('due soon covers today to 7 days ahead, earliest first', () {
      final summary = DebtSummary.of(
        [
          _d('edge', _youOwe, 100, DateTime(2026, 10, 17)),
          _d('late', _youOwe, 100, DateTime(2026, 10, 18)),
          _d('over', _youOwe, 100, DateTime(2026, 10, 9)),
          _d('mid', _youOwe, 100, DateTime(2026, 10, 12)),
          _d('today', _youOwe, 100, DateTime(2026, 10, 10)),
        ],
        today: _today,
      );

      expect(summary.dueSoon.map((d) => d.id), ['today', 'mid', 'edge']);
    });

    test('partially settled counts open debts that have a payment', () {
      final summary = DebtSummary.of(
        [
          _d('a', _youOwe, 500, DateTime(2026, 10, 20),
              payments: [_pay('p1', 100)]),
          _d('b', _owedToYou, 500, DateTime(2026, 10, 1),
              payments: [_pay('p2', 100)]), // overdue, still counts
          _d('c', _youOwe, 500, DateTime(2026, 10, 20)), // no payments
          _d('d', _youOwe, 500, DateTime(2026, 10, 20),
              payments: [_pay('p3', 500)]), // fully paid
        ],
        today: _today,
      );

      expect(summary.partiallySettledCount, 2);
    });
  });

  group('toDueItems', () {
    test('shows what is left, with the right kind and title', () {
      final items = DebtRules.toDueItems([
        _d('a', _youOwe, 500, DateTime(2026, 10, 20),
            person: 'Fatir', payments: [_pay('p1', 200)]),
        _d('b', _owedToYou, 300, DateTime(2026, 10, 15), person: 'Rahim'),
      ]);

      expect(items.length, 2);

      expect(items[0].title, 'Repay Fatir');
      expect(items[0].amount, Money.taka(300));
      expect(items[0].kind, DueKind.debtYouOwe);

      expect(items[1].title, 'Rahim will pay you');
      expect(items[1].amount, Money.taka(300));
      expect(items[1].kind, DueKind.owedToYou);
    });

    test('skips paid and cancelled debts', () {
      final items = DebtRules.toDueItems([
        _d('a', _youOwe, 500, DateTime(2026, 10, 20),
            payments: [_pay('p1', 500)]),
        _d('b', _owedToYou, 300, DateTime(2026, 10, 15),
            cancelledAt: DateTime(2026, 10, 6)),
      ]);

      expect(items, isEmpty);
    });
  });
}