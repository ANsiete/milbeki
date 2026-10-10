// Small date and time formatters, so every screen shows dates the same way.
class AppDates {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// 15 Oct
  static String shortDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]}';

  /// Sat, 10 Oct
  static String weekdayDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${shortDate(date)}';

  /// 3:05 PM
  static String time12h(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }
}