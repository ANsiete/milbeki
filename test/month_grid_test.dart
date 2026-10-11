import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/month_grid.dart';

void main() {
  group('October 2026 (the 1st is a Thursday)', () {
    test('weeks starting on Saturday: 6 rows, 26 Sep to 6 Nov', () {
      final grid = MonthGrid.of(2026, 10); // Saturday is the default
      expect(grid.days.length, 42);
      expect(grid.weeks.length, 6);
      expect(grid.days.first, DateTime(2026, 9, 26));
      expect(grid.days.last, DateTime(2026, 11, 6));
      expect(grid.days[5], DateTime(2026, 10, 1)); // 5 filler days first
    });

    test('weeks starting on Sunday: 5 rows, 27 Sep to 31 Oct', () {
      final grid = MonthGrid.of(2026, 10, weekStartsOn: DateTime.sunday);
      expect(grid.days.length, 35);
      expect(grid.days.first, DateTime(2026, 9, 27));
      expect(grid.days.last, DateTime(2026, 10, 31));
    });

    test('every row starts on the chosen weekday', () {
      for (final start in [DateTime.saturday, DateTime.sunday, DateTime.monday]) {
        final grid = MonthGrid.of(2026, 10, weekStartsOn: start);
        for (final week in grid.weeks) {
          expect(week.length, 7);
          expect(week.first.weekday, start);
        }
      }
    });

    test('the days are consecutive and the month has exactly 31 of them', () {
      final grid = MonthGrid.of(2026, 10);
      for (var i = 1; i < grid.days.length; i++) {
        final previous = grid.days[i - 1];
        expect(
          grid.days[i],
          DateTime(previous.year, previous.month, previous.day + 1),
        );
      }
      expect(grid.days.where(grid.isInMonth).length, 31);
    });

    test('isInMonth separates the month from the filler days', () {
      final grid = MonthGrid.of(2026, 10);
      expect(grid.isInMonth(DateTime(2026, 10, 1)), isTrue);
      expect(grid.isInMonth(DateTime(2026, 10, 31)), isTrue);
      expect(grid.isInMonth(DateTime(2026, 9, 30)), isFalse);
      expect(grid.isInMonth(DateTime(2026, 11, 1)), isFalse);
    });

    test('10 Oct 2026 is a Saturday, the first column', () {
      final grid = MonthGrid.of(2026, 10);
      expect(grid.days[14], DateTime(2026, 10, 10));
      expect(grid.days[14].weekday, DateTime.saturday);
    });
  });

  group('edge months', () {
    test('a month that starts on the first day of the week has no filler before it', () {
      // 1 Aug 2026 is a Saturday.
      final grid = MonthGrid.of(2026, 8);
      expect(grid.days.length, 35);
      expect(grid.days.first, DateTime(2026, 8, 1));
      expect(grid.days.last, DateTime(2026, 9, 4));
    });

    test('a 28-day month that fits four exact weeks', () {
      // 1 Feb 2027 is a Monday, and February 2027 has 28 days.
      final grid = MonthGrid.of(2027, 2, weekStartsOn: DateTime.monday);
      expect(grid.days.length, 28);
      expect(grid.weeks.length, 4);
      expect(grid.days.first, DateTime(2027, 2, 1));
      expect(grid.days.last, DateTime(2027, 2, 28));
    });

    test('February in a leap year includes the 29th', () {
      // 1 Feb 2028 is a Tuesday.
      final grid = MonthGrid.of(2028, 2, weekStartsOn: DateTime.monday);
      expect(grid.days.length, 35);
      expect(grid.days.first, DateTime(2028, 1, 31));
      expect(grid.days.last, DateTime(2028, 3, 5));
      expect(grid.isInMonth(DateTime(2028, 2, 29)), isTrue);
      expect(grid.isInMonth(DateTime(2028, 3, 1)), isFalse);
    });

    test('a month at the end of the year runs into January', () {
      // 1 Dec 2026 is a Tuesday.
      final grid = MonthGrid.of(2026, 12);
      expect(grid.days.length, 35);
      expect(grid.days.first, DateTime(2026, 11, 28));
      expect(grid.days.last, DateTime(2027, 1, 1));
    });

    test('month 13 means January of the next year', () {
      final grid = MonthGrid.of(2026, 13);
      expect(grid.year, 2027);
      expect(grid.month, 1);
    });
  });

  group('addMonths', () {
    test('moves forward and back across year boundaries', () {
      expect(MonthGrid.addMonths(DateTime(2026, 12, 15), 1), DateTime(2027, 1, 1));
      expect(MonthGrid.addMonths(DateTime(2026, 1, 31), -1), DateTime(2025, 12, 1));
      expect(MonthGrid.addMonths(DateTime(2026, 10, 10), 0), DateTime(2026, 10, 1));
    });
  });

  test('a weekStartsOn outside 1 to 7 is rejected', () {
    expect(() => MonthGrid.of(2026, 10, weekStartsOn: 0), throwsArgumentError);
    expect(() => MonthGrid.of(2026, 10, weekStartsOn: 8), throwsArgumentError);
  });
}