// Adds .dateOnly to every DateTime: the same day at midnight.
// Comparing dates this way ignores the time of day, so "due today at 11 PM"
// and "now, at 3 PM" are the same day.
extension DateOnly on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);
}