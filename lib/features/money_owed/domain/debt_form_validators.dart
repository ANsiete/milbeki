import 'package:milbeki_app/core/utils/date_only.dart';

// Each validator returns an error message, or null when the input is fine.
// The amount reuses ExpenseValidators.amount.
class DebtFormValidators {
  static String? personName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return "Enter the person's name";
    if (text.length < 2) return 'Name must be at least 2 characters';
    if (text.length > 50) return 'Name must be 50 characters or fewer';
    return null;
  }

  /// Today is fine; tomorrow is not. Only the date matters, not the time.
  static String? startDate(DateTime start, DateTime now) {
    if (start.dateOnly.isAfter(now.dateOnly)) {
      return 'The start date cannot be in the future';
    }
    return null;
  }

  /// A due date in the past is allowed (an old debt), but not before the start.
  static String? dueDate(DateTime? due, DateTime start) {
    if (due == null) return 'Choose a due date';
    if (due.dateOnly.isBefore(start.dateOnly)) {
      return 'The due date cannot be before the start date';
    }
    return null;
  }
}