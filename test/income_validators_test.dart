import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/features/transactions/domain/income_validators.dart';

void main() {
  final now = DateTime(2026, 10, 10, 15, 30);

  group('receivedAt', () {
    test('accepts now, the past, and a one-minute margin', () {
      expect(IncomeValidators.receivedAt(now, now), isNull);
      expect(
        IncomeValidators.receivedAt(DateTime(2026, 10, 9, 8, 0), now),
        isNull,
      );
      expect(
        IncomeValidators.receivedAt(now.add(const Duration(minutes: 1)), now),
        isNull,
      );
    });

    test('rejects later times and points to Expected', () {
      final error = IncomeValidators.receivedAt(
        now.add(const Duration(minutes: 2)),
        now,
      );
      expect(error, isNotNull);
      expect(error, contains('Choose Expected'));

      expect(
        IncomeValidators.receivedAt(DateTime(2026, 10, 11), now),
        isNotNull,
      );
    });
  });

  group('expectedDate', () {
    test('accepts today (whatever the time) and later days', () {
      expect(IncomeValidators.expectedDate(DateTime(2026, 10, 10), now), isNull);
      expect(
        IncomeValidators.expectedDate(DateTime(2026, 10, 10, 9, 0), now),
        isNull,
      );
      expect(IncomeValidators.expectedDate(DateTime(2026, 10, 17), now), isNull);
    });

    test('rejects a day in the past', () {
      expect(
        IncomeValidators.expectedDate(DateTime(2026, 10, 9), now),
        'An expected date cannot be in the past',
      );
    });
  });
}