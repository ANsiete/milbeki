// A budget cycle runs from the user's chosen start day to the day before the
// next start day. With start day 5, one cycle is 5 Oct to 4 Nov.
class BudgetCycle {
  const BudgetCycle({required this.start, required this.end});

  /// First day of the cycle (midnight).
  final DateTime start;

  /// Last day of the cycle, inclusive (midnight).
  final DateTime end;

  /// Finds the cycle that contains [date].
  /// [startDay] must be 1 to 28, so that every month has that day.
  factory BudgetCycle.containing(DateTime date, {required int startDay}) {
    if (startDay < 1 || startDay > 28) {
      throw ArgumentError.value(startDay, 'startDay', 'Must be between 1 and 28');
    }

    // Drop the time of day, so 23:59 and 00:01 count as the same day.
    final day = DateTime(date.year, date.month, date.day);

    // Before this month's start day, the cycle began last month.
    // DateTime fixes overflow itself: month 0 means December of the previous year.
    final startMonth = day.day >= startDay ? day.month : day.month - 1;
    final start = DateTime(day.year, startMonth, startDay);

    // The next cycle starts one month later. The cycle ends the day before it.
    // Day 0 of a month means "the last day of the previous month".
    final nextStart = DateTime(start.year, start.month + 1, startDay);
    final end = DateTime(nextStart.year, nextStart.month, nextStart.day - 1);

    return BudgetCycle(start: start, end: end);
  }

  /// True when [date] falls inside the cycle (both ends included).
  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  /// Days left in the cycle, counting [today] itself.
  /// On the last day of the cycle this is 1.
  int daysLeftFrom(DateTime today) {
    // UTC dates avoid daylight-saving shifts making a day 23 or 25 hours long.
    final endUtc = DateTime.utc(end.year, end.month, end.day);
    final todayUtc = DateTime.utc(today.year, today.month, today.day);
    return endUtc.difference(todayUtc).inDays + 1;
  }
}