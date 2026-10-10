import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/budget_cycle.dart';

void main() {
  group('BudgetCycle.containing', () {
    test('start day 1 gives the calendar month', () {
      final cycle = BudgetCycle.containing(DateTime(2026, 10, 10), startDay: 1);
      expect(cycle.start, DateTime(2026, 10, 1));
      expect(cycle.end, DateTime(2026, 10, 31));
    });

    test('start day 5, after the start day: this month to next month', () {
      final cycle = BudgetCycle.containing(DateTime(2026, 10, 10), startDay: 5);
      expect(cycle.start, DateTime(2026, 10, 5));
      expect(cycle.end, DateTime(2026, 11, 4));
    });

    test('start day 5, before the start day: last month to this month', () {
      final cycle = BudgetCycle.containing(DateTime(2026, 10, 3), startDay: 5);
      expect(cycle.start, DateTime(2026, 9, 5));
      expect(cycle.end, DateTime(2026, 10, 4));
    });

    test('the start day itself belongs to the new cycle', () {
      final cycle = BudgetCycle.containing(DateTime(2026, 10, 5), startDay: 5);
      expect(cycle.start, DateTime(2026, 10, 5));
    });

    test('the day before the start day belongs to the old cycle', () {
      final cycle = BudgetCycle.containing(DateTime(2026, 10, 4), startDay: 5);
      expect(cycle.start, DateTime(2026, 9, 5));
      expect(cycle.end, DateTime(2026, 10, 4));
    });

    test('works across New Year (early January)', () {
      final cycle = BudgetCycle.containing(DateTime(2027, 1, 3), startDay: 5);
      expect(cycle.start, DateTime(2026, 12, 5));
      expect(cycle.end, DateTime(2027, 1, 4));
    });

    test('works across New Year (late December)', () {
      final cycle = BudgetCycle.containing(DateTime(2026, 12, 20), startDay: 15);
      expect(cycle.start, DateTime(2026, 12, 15));
      expect(cycle.end, DateTime(2027, 1, 14));
    });

    test('handles 29 February in a leap year', () {
      final cycle = BudgetCycle.containing(DateTime(2028, 2, 10), startDay: 1);
      expect(cycle.end, DateTime(2028, 2, 29));
    });

    test('ignores the time of day', () {
      final cycle =
          BudgetCycle.containing(DateTime(2026, 10, 10, 23, 59), startDay: 1);
      expect(cycle.start, DateTime(2026, 10, 1));
    });

    test('rejects start days outside 1 to 28', () {
      expect(
        () => BudgetCycle.containing(DateTime(2026, 10, 10), startDay: 0),
        throwsArgumentError,
      );
      expect(
        () => BudgetCycle.containing(DateTime(2026, 10, 10), startDay: 29),
        throwsArgumentError,
      );
    });
  });

  group('days left and contains', () {
    test('counts today: 10 Oct to 31 Oct is 22 days', () {
      final cycle = BudgetCycle.containing(DateTime(2026, 10, 10), startDay: 1);
      expect(cycle.daysLeftFrom(DateTime(2026, 10, 10)), 22);
    });

    test('start day 5: 10 Oct to 4 Nov is 26 days', () {
      final cycle = BudgetCycle.containing(DateTime(2026, 10, 10), startDay: 5);
      expect(cycle.daysLeftFrom(DateTime(2026, 10, 10)), 26);
    });

    test('first day has the whole month, last day has 1', () {
      final cycle = BudgetCycle.containing(DateTime(2026, 10, 10), startDay: 1);
      expect(cycle.daysLeftFrom(DateTime(2026, 10, 1)), 31);
      expect(cycle.daysLeftFrom(DateTime(2026, 10, 31)), 1);
    });

    test('contains includes both ends and excludes outside dates', () {
      final cycle = BudgetCycle.containing(DateTime(2026, 10, 10), startDay: 1);
      expect(cycle.contains(DateTime(2026, 10, 1)), isTrue);
      expect(cycle.contains(DateTime(2026, 10, 31, 23, 0)), isTrue);
      expect(cycle.contains(DateTime(2026, 11, 1)), isFalse);
      expect(cycle.contains(DateTime(2026, 9, 30)), isFalse);
    });
  });
}