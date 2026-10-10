import 'package:milbeki_app/core/utils/money.dart';

// Each validator returns an error message, or null when the input is fine.
class ExpenseValidators {
  // Digits, then optionally a dot and one or two more digits.
  static final RegExp _amountPattern = RegExp(r'^\d+(\.\d{1,2})?$');

  static String? amount(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter an amount';
    if (!_amountPattern.hasMatch(text)) {
      return 'Enter an amount like 120 or 120.50';
    }

    // At most 8 digits before the dot (under ৳10 crore). This also keeps the
    // number small enough for Money.parse to handle safely.
    final wholePart = text.split('.').first;
    if (wholePart.length > 8) return 'That amount is too large';

    if (Money.parse(text).paisa <= 0) return 'Amount must be greater than 0';
    return null;
  }

  /// A one-minute margin allows for the clock moving between opening the
  /// form and tapping Save.
  static String? occurredAt(DateTime value, DateTime now) {
    if (value.isAfter(now.add(const Duration(minutes: 1)))) {
      return 'An expense cannot be in the future';
    }
    return null;
  }
}
