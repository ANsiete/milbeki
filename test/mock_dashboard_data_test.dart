import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/dashboard/data/mock_dashboard_data.dart';
import 'package:milbeki_app/features/dashboard/domain/daily_limit.dart';

void main() {
  final data = MockDashboardData.sample();

  test('the sample cycle is 1 to 31 October 2026 and contains today', () {
    expect(data.cycle.start, DateTime(2026, 10, 1));
    expect(data.cycle.end, DateTime(2026, 10, 31));
    expect(data.cycle.contains(data.now), isTrue);
  });

  test('category spending adds up to the period expenses', () {
    final total = data.categories
        .fold<Money>(Money.zero, (sum, c) => sum + c.spent);
    expect(total, data.periodExpenses);
  });

  test("today's expenses add up and all happened today", () {
    expect(data.spentToday, Money.taka(280));
    for (final expense in data.todayExpenses) {
      expect(expense.time.year, data.now.year);
      expect(expense.time.month, data.now.month);
      expect(expense.time.day, data.now.day);
    }
  });

  test('the daily limit for the sample data', () {
    final result = DailyLimitCalculator.calculate(
      moneyHeld: data.moneyHeld,
      dueItems: data.dueItems,
      savingsRemaining: data.savingsRemaining,
      spentToday: data.spentToday,
      cycle: data.cycle,
      today: data.now,
    );

    expect(result.spendable, Money.taka(6300));
    expect(result.daysLeft, 22);
    expect(result.dailyLimit, Money.taka(299));
    expect(result.remainingToday, Money.taka(19));
  });
}