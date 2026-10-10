import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/budget_cycle.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/dashboard/domain/daily_limit.dart';
import 'package:milbeki_app/features/dashboard/domain/dashboard_models.dart';

DueItem _bill(String title, int taka, DateTime due) => DueItem(
      title: title,
      amount: Money.taka(taka),
      dueDate: due,
      kind: DueKind.bill,
    );

DueItem _debt(String title, int taka, DateTime due) => DueItem(
      title: title,
      amount: Money.taka(taka),
      dueDate: due,
      kind: DueKind.debtYouOwe,
    );

DueItem _receivable(String title, int taka, DateTime due) => DueItem(
      title: title,
      amount: Money.taka(taka),
      dueDate: due,
      kind: DueKind.owedToYou,
    );

// Cycle is 1 to 31 October 2026. The default "today" is 22 Oct = 10 days left.
DailyLimit _calc({
  required Money held,
  List<DueItem> items = const [],
  Money savings = Money.zero,
  Money spentToday = Money.zero,
  DateTime? today,
}) {
  final day = today ?? DateTime(2026, 10, 22);
  return DailyLimitCalculator.calculate(
    moneyHeld: held,
    dueItems: items,
    savingsRemaining: savings,
    spentToday: spentToday,
    cycle: BudgetCycle.containing(day, startDay: 1),
    today: day,
  );
}

void main() {
  test('Phase 1 worked example: 14,600 held gives 630 per day', () {
    final result = _calc(
      held: Money.taka(14600),
      items: [
        _bill('Rent', 5000, DateTime(2026, 10, 25)),
        _bill('Internet', 1000, DateTime(2026, 10, 28)),
        _debt('Fatir', 300, DateTime(2026, 10, 28)),
        _receivable('Rahim', 200, DateTime(2026, 10, 25)),
      ],
      savings: Money.taka(2000),
    );

    expect(result.billsDue, Money.taka(6000));
    expect(result.debtsDue, Money.taka(300));
    expect(result.savingsReserved, Money.taka(2000));
    expect(result.spendable, Money.taka(6300));
    expect(result.daysLeft, 10);
    expect(result.dailyLimit, Money.taka(630));
    expect(result.remainingToday, Money.taka(630));
    expect(result.isShortfall, isFalse);
  });

  test('money owed to you never changes the limit', () {
    final without = _calc(held: Money.taka(5000));
    final withReceivable = _calc(
      held: Money.taka(5000),
      items: [_receivable('Rahim', 9000, DateTime(2026, 10, 25))],
    );
    expect(withReceivable.spendable, without.spendable);
    expect(withReceivable.dailyLimit, without.dailyLimit);
  });

  test('items due after the cycle ends are not reserved', () {
    final result = _calc(
      held: Money.taka(5000),
      items: [_bill('Next month', 9999, DateTime(2026, 11, 5))],
    );
    expect(result.billsDue, Money.zero);
  });

  test('an item due on the last day, with a time, is reserved', () {
    final result = _calc(
      held: Money.taka(5000),
      items: [_bill('Last day', 700, DateTime(2026, 10, 31, 15, 0))],
    );
    expect(result.billsDue, Money.taka(700));
  });

  test('an overdue unpaid bill is still reserved', () {
    final result = _calc(
      held: Money.taka(5000),
      items: [_bill('Overdue', 500, DateTime(2026, 10, 1))],
    );
    expect(result.billsDue, Money.taka(500));
    expect(result.spendable, Money.taka(4500));
  });

  test('a shortfall gives a limit of zero and reports the gap', () {
    final result = _calc(
      held: Money.taka(3000),
      items: [_bill('Rent', 6000, DateTime(2026, 10, 25))],
    );
    expect(result.spendable, Money.taka(-3000));
    expect(result.dailyLimit, Money.zero);
    expect(result.isShortfall, isTrue);
    expect(result.shortfall, Money.taka(3000));
  });

  test('exactly enough for commitments gives zero but no shortfall', () {
    final result = _calc(
      held: Money.taka(6000),
      items: [_bill('Rent', 6000, DateTime(2026, 10, 25))],
    );
    expect(result.spendable, Money.zero);
    expect(result.dailyLimit, Money.zero);
    expect(result.isShortfall, isFalse);
  });

  test('the limit is rounded down to whole taka', () {
    // 29 Oct leaves 3 days. 1,000 / 3 = 333.33, shown as 333.
    final result = _calc(held: Money.taka(1000), today: DateTime(2026, 10, 29));
    expect(result.daysLeft, 3);
    expect(result.dailyLimit, Money.taka(333));
  });

  test('on the last day the whole spendable amount is the limit', () {
    final result = _calc(held: Money.taka(500), today: DateTime(2026, 10, 31));
    expect(result.daysLeft, 1);
    expect(result.dailyLimit, Money.taka(500));
  });

  test('saving more than the target does not raise the limit', () {
    final result = _calc(held: Money.taka(1000), savings: Money.taka(-300));
    expect(result.savingsReserved, Money.zero);
    expect(result.spendable, Money.taka(1000));
  });

  test("today's spending is added back, not subtracted twice", () {
    // Sample data: 14,600 held, 280 already spent today, 22 days left.
    final items = [
      _bill('Rent', 5000, DateTime(2026, 10, 15)),
      _bill('Internet', 1000, DateTime(2026, 10, 20)),
      _debt('Fatir', 300, DateTime(2026, 10, 20)),
    ];
    final result = _calc(
      held: Money.taka(14600),
      items: items,
      savings: Money.taka(2000),
      spentToday: Money.taka(280),
      today: DateTime(2026, 10, 10),
    );

    expect(result.spendable, Money.taka(6300));
    expect(result.startOfDay, Money.taka(6580));
    expect(result.daysLeft, 22);
    expect(result.dailyLimit, Money.taka(299));
    expect(result.remainingToday, Money.taka(19));
  });

  test('spending over the limit gives a negative remaining amount', () {
    final result = _calc(
      held: Money.taka(14600),
      items: [
        _bill('Rent', 5000, DateTime(2026, 10, 15)),
        _bill('Internet', 1000, DateTime(2026, 10, 20)),
        _debt('Fatir', 300, DateTime(2026, 10, 20)),
      ],
      savings: Money.taka(2000),
      spentToday: Money.taka(500),
      today: DateTime(2026, 10, 10),
    );

    expect(result.dailyLimit, Money.taka(309));
    expect(result.remainingToday, Money.taka(-191));
    expect(result.remainingToday.isNegative, isTrue);
  });
}