import 'package:milbeki_app/core/utils/date_only.dart';

// Each validator returns an error message, or null when the input is fine.
// The amount reuses ExpenseValidators.amount.
class IncomeValidators {
  /// Money that has arrived cannot be dated in the future.
  /// A one-minute margin allows for the clock moving while the form is open.
  static String? receivedAt(DateTime value, DateTime now) {
    if (value.isAfter(now.add(const Duration(minutes: 1)))) {
      return 'Received income cannot be dated in the future. '
          'Choose Expected instead.';
    }
    return null;
  }

  /// An expected day must be today or later. Only the date matters.
  static String? expectedDate(DateTime date, DateTime now) {
    if (date.dateOnly.isBefore(now.dateOnly)) {
      return 'An expected date cannot be in the past';
    }
    return null;
  }
}