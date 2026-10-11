// The days shown on a month calendar: the month itself, plus the few days of
// the neighbouring months that fill the first and last week.
class MonthGrid {
  const MonthGrid._({
    required this.year,
    required this.month,
    required this.days,
  });

  /// [weekStartsOn] uses Dart's numbers: DateTime.monday (1) to DateTime.sunday (7).
  /// The default is Saturday, the first day of the Bangladeshi week.
  factory MonthGrid.of(
    int year,
    int month, {
    int weekStartsOn = DateTime.saturday,
  }) {
    if (weekStartsOn < DateTime.monday || weekStartsOn > DateTime.sunday) {
      throw ArgumentError.value(
        weekStartsOn,
        'weekStartsOn',
        'Use DateTime.monday (1) to DateTime.sunday (7)',
      );
    }

    // DateTime fixes overflow itself: month 13 means January of the next year.
    final first = DateTime(year, month, 1);

    // Day 0 of the next month is the last day of this one.
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;

    // How many days of the previous month appear before the 1st.
    final leading = (first.weekday - weekStartsOn + 7) % 7;

    // Round up to whole weeks.
    final weekCount = (leading + daysInMonth + 6) ~/ 7;

    // A day number of 0 or less means "into the previous month".
    final days = [
      for (var i = 0; i < weekCount * 7; i++)
        DateTime(first.year, first.month, 1 - leading + i),
    ];

    return MonthGrid._(
      year: first.year,
      month: first.month,
      days: List.unmodifiable(days),
    );
  }

  final int year;
  final int month;

  /// Every cell of the grid, in order, at midnight. Always a whole number of weeks.
  final List<DateTime> days;

  /// The grid split into rows of 7 days.
  List<List<DateTime>> get weeks => [
        for (var i = 0; i < days.length; i += 7) days.sublist(i, i + 7),
      ];

  /// True for days of this month, false for the filler days around it.
  bool isInMonth(DateTime date) => date.year == year && date.month == month;

  /// The first day of the month [count] months away (negative goes back).
  static DateTime addMonths(DateTime date, int count) =>
      DateTime(date.year, date.month + count, 1);
}