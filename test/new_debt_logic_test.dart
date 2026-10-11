import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/money_owed/application/debt_store.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_form_validators.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';

Debt _debt(String id, String name) => Debt(
      id: id,
      personName: name,
      direction: DebtDirection.youOwe,
      originalAmount: Money.taka(500),
      startDate: DateTime(2026, 10, 1),
      dueDate: DateTime(2026, 10, 20),
    );

void main() {
  group('personName', () {
    test('accepts 2 to 50 characters after trimming', () {
      expect(DebtFormValidators.personName('Al'), isNull);
      expect(DebtFormValidators.personName('  Tania Rahman  '), isNull);
      expect(DebtFormValidators.personName('A' * 50), isNull);
    });

    test('rejects empty, one character, and too long', () {
      expect(DebtFormValidators.personName(''), "Enter the person's name");
      expect(DebtFormValidators.personName(null), "Enter the person's name");
      expect(DebtFormValidators.personName('   '), "Enter the person's name");
      expect(
        DebtFormValidators.personName('A'),
        'Name must be at least 2 characters',
      );
      expect(
        DebtFormValidators.personName('A' * 51),
        'Name must be 50 characters or fewer',
      );
    });
  });

  group('startDate', () {
    final now = DateTime(2026, 10, 10, 15, 30);

    test('accepts today, whatever the time, and the past', () {
      expect(DebtFormValidators.startDate(DateTime(2026, 10, 10), now), isNull);
      expect(
        DebtFormValidators.startDate(DateTime(2026, 10, 10, 23, 0), now),
        isNull,
      );
      expect(DebtFormValidators.startDate(DateTime(2025, 1, 5), now), isNull);
    });

    test('rejects tomorrow', () {
      expect(
        DebtFormValidators.startDate(DateTime(2026, 10, 11), now),
        'The start date cannot be in the future',
      );
    });
  });

  group('dueDate', () {
    final start = DateTime(2026, 9, 1);

    test('is required', () {
      expect(DebtFormValidators.dueDate(null, start), 'Choose a due date');
    });

    test('accepts the start day and later, even if already in the past', () {
      expect(DebtFormValidators.dueDate(DateTime(2026, 9, 1), start), isNull);
      expect(DebtFormValidators.dueDate(DateTime(2026, 9, 5), start), isNull);
      expect(DebtFormValidators.dueDate(DateTime(2027, 1, 1), start), isNull);
    });

    test('rejects a day before the start', () {
      expect(
        DebtFormValidators.dueDate(DateTime(2026, 8, 31), start),
        'The due date cannot be before the start date',
      );
    });
  });

  group('DebtStore', () {
    test('starts with a private copy of the given debts', () {
      final source = [_debt('a', 'Fatir')];
      final store = DebtStore(source);

      source.add(_debt('b', 'Rahim')); // changing the original list...
      expect(store.debts.length, 1); // ...does not touch the store
    });

    test('debts is read-only', () {
      final store = DebtStore([_debt('a', 'Fatir')]);
      expect(() => store.debts.add(_debt('b', 'Rahim')), throwsUnsupportedError);
    });

    test('add appends a debt and notifies once', () {
      final store = DebtStore([_debt('a', 'Fatir')]);
      var calls = 0;
      store.addListener(() => calls++);

      store.add(_debt('b', 'Rahim'));

      expect(store.debts.map((d) => d.id), ['a', 'b']);
      expect(calls, 1);
    });

    test('a debt with an existing id is ignored and does not notify', () {
      final store = DebtStore([_debt('a', 'Fatir')]);
      var calls = 0;
      store.addListener(() => calls++);

      store.add(_debt('a', 'Someone else'));

      expect(store.debts.length, 1);
      expect(store.debts.first.personName, 'Fatir');
      expect(calls, 0);
    });

    test('replace swaps the debt by id, keeps the order, and notifies', () {
      final a = _debt('a', 'Fatir');
      final b = _debt('b', 'Rahim');
      final store = DebtStore([a, b]);
      var calls = 0;
      store.addListener(() => calls++);

      final updated = a.withPayment(
        DebtPayment(
          id: 'p1',
          amount: Money.taka(100),
          paidAt: DateTime(2026, 10, 2),
        ),
      );
      store.replace(updated);

      expect(store.debts.map((d) => d.id), ['a', 'b']);
      expect(store.debts.first.outstanding, Money.taka(400));
      expect(calls, 1);
    });

    test('replacing an unknown id does nothing', () {
      final store = DebtStore([_debt('a', 'Fatir')]);
      var calls = 0;
      store.addListener(() => calls++);

      store.replace(_debt('zzz', 'Nobody'));

      expect(store.debts.length, 1);
      expect(calls, 0);
    });
  });
}