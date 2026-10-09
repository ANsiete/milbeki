// Money is stored as a whole number of paisa (1 taka = 100 paisa),
// so ৳125.50 is stored as 12550. Integers never lose precision.
class Money {
  const Money(this.paisa);

  /// Creates money from whole taka: Money.taka(500) is ৳500.
  factory Money.taka(int taka) => Money(taka * 100);

  /// Reads text such as "125", "125.5", "125.50" or "-40.25".
  /// Throws a FormatException for anything else (letters, 3 decimals...).
  factory Money.parse(String text) {
    final match = RegExp(r'^(-)?(\d+)(?:\.(\d{1,2}))?$').firstMatch(text.trim());
    if (match == null) {
      throw FormatException('Invalid money amount: "$text"');
    }
    final isNegative = match.group(1) != null;
    final whole = int.parse(match.group(2)!);
    // "5" becomes "50", so "125.5" means 125 taka and 50 paisa.
    final fraction = int.parse((match.group(3) ?? '').padRight(2, '0'));
    final paisa = whole * 100 + fraction;
    return Money(isNegative ? -paisa : paisa);
  }

  static const Money zero = Money(0);

  final int paisa;

  bool get isNegative => paisa < 0;

  Money operator +(Money other) => Money(paisa + other.paisa);
  Money operator -(Money other) => Money(paisa - other.paisa);

  @override
  bool operator ==(Object other) => other is Money && other.paisa == paisa;

  @override
  int get hashCode => paisa.hashCode;

  /// Formats like ৳1,25,000 (Bangladeshi digit grouping).
  /// Decimals appear only when paisa is not zero, unless you ask for them.
  String format({bool alwaysShowDecimals = false}) {
    final absolute = paisa.abs();
    final whole = absolute ~/ 100;
    final fraction = absolute % 100;
    final sign = paisa < 0 ? '-' : '';
    final decimals = (alwaysShowDecimals || fraction != 0)
        ? '.${fraction.toString().padLeft(2, '0')}'
        : '';
    return '$sign৳${_groupDigits(whole.toString())}$decimals';
  }

  // Last 3 digits form one group, then every 2 digits: 1234567 -> 12,34,567
  static String _groupDigits(String digits) {
    if (digits.length <= 3) return digits;
    final lastThree = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    return '${groups.join(',')},$lastThree';
  }

  @override
  String toString() => format(alwaysShowDecimals: true);
}