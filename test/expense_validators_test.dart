import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/features/transactions/domain/expense_validators.dart';

void main() {
  group('amount', () {
    test('accepts whole and decimal amounts', () {
      expect(ExpenseValidators.amount('120'), isNull);
      expect(ExpenseValidators.amount('120.5'), isNull);
      expect(ExpenseValidators.amount('120.50'), isNull);
      expect(ExpenseValidators.amount('0.01'), isNull);
      expect(ExpenseValidators.amount('  75  '), isNull);
    });

    test('rejects empty input', () {
      expect(ExpenseValidators.amount(''), 'Enter an amount');
      expect(ExpenseValidators.amount(null), 'Enter an amount');
      expect(ExpenseValidators.amount('   '), 'Enter an amount');
    });

    test('rejects zero', () {
      expect(ExpenseValidators.amount('0'), 'Amount must be greater than 0');
      expect(ExpenseValidators.amount('0.00'), 'Amount must be greater than 0');
    });

    test('rejects malformed amounts', () {
      expect(ExpenseValidators.amount('abc'), isNotNull);
      expect(ExpenseValidators.amount('12.345'), isNotNull);
      expect(ExpenseValidators.amount('1,000'), isNotNull);
      expect(ExpenseValidators.amount('.5'), isNotNull);
      expect(ExpenseValidators.amount('-5'), isNotNull);
    });

    test('rejects amounts with more than 8 whole digits', () {
      expect(ExpenseValidators.amount('99999999'), isNull);
      expect(ExpenseValidators.amount('123456789'), 'That amount is too large');
      expect(
        ExpenseValidators.amount('99999999999999999999999'),
        'That amount is too large',
      );
    });
  });

  group('occurredAt', () {
    final now = DateTime(2026, 10, 10, 15, 30);

    test('accepts now, the past, and a one-minute margin', () {
      expect(ExpenseValidators.occurredAt(now, now), isNull);
      expect(
        ExpenseValidators.occurredAt(DateTime(2026, 10, 9, 8, 0), now),
        isNull,
      );
      expect(
        ExpenseValidators.occurredAt(now.add(const Duration(minutes: 1)), now),
        isNull,
      );
    });

    test('rejects times in the future', () {
      expect(
        ExpenseValidators.occurredAt(now.add(const Duration(minutes: 2)), now),
        'An expense cannot be in the future',
      );
      expect(
        ExpenseValidators.occurredAt(DateTime(2026, 10, 11), now),
        isNotNull,
      );
    });
  });
}