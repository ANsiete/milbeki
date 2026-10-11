import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/date_format.dart';

void main() {
  test('shortDate', () {
    expect(AppDates.shortDate(DateTime(2026, 10, 15)), '15 Oct');
    expect(AppDates.shortDate(DateTime(2026, 1, 3)), '3 Jan');
  });

  test('weekdayDate (10 Oct 2026 is a Saturday)', () {
    expect(AppDates.weekdayDate(DateTime(2026, 10, 10)), 'Sat, 10 Oct');
  });

  test('time12h handles midnight, morning, noon and afternoon', () {
    expect(AppDates.time12h(DateTime(2026, 10, 10, 0, 5)), '12:05 AM');
    expect(AppDates.time12h(DateTime(2026, 10, 10, 9, 7)), '9:07 AM');
    expect(AppDates.time12h(DateTime(2026, 10, 10, 12, 0)), '12:00 PM');
    expect(AppDates.time12h(DateTime(2026, 10, 10, 15, 30)), '3:30 PM');
  });

  test('monthYear uses the full month name', () {
    expect(AppDates.monthYear(DateTime(2026, 10, 15)), 'October 2026');
    expect(AppDates.monthYear(DateTime(2027, 1, 1)), 'January 2027');
    expect(AppDates.monthYear(DateTime(2026, 5, 31)), 'May 2026');
  });
}