import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/setup/domain/setup_models.dart';
import 'package:milbeki_app/features/setup/domain/setup_validator.dart';

import 'support/setup_scenario.dart';

List<SetupIssue> _validate(SetupData data) =>
    SetupValidator.validate(data, now: setupNow);

List<String> _messages(SetupData data) =>
    _validate(data).map((i) => i.message).toList();

List<SetupStep> _steps(SetupData data) =>
    _validate(data).map((i) => i.step).toList();

// Only a valid name is filled in. Everything else is skipped.
const _base = SetupData(displayName: 'Ashraf');

IncomeEntry _income({
  String name = 'Tutoring',
  Money? amount,
  int? day = 10,
  SetupFrequency frequency = SetupFrequency.monthly,
  String? note,
}) =>
    IncomeEntry(
      id: 'i',
      name: name,
      amount: amount ?? Money.taka(100),
      frequency: frequency,
      dayOfMonth: day,
      note: note,
    );

FixedExpenseEntry _fixed({
  String title = 'Rent',
  Money? amount,
  int? day = 5,
  SetupFrequency frequency = SetupFrequency.monthly,
}) =>
    FixedExpenseEntry(
      id: 'f',
      kind: FixedExpenseKind.rent,
      title: title,
      amount: amount ?? Money.taka(100),
      frequency: frequency,
      dayOfMonth: day,
    );

OpeningBalance _account(String name, Money amount, {String id = 'a'}) =>
    OpeningBalance(
      id: id,
      name: name,
      type: SetupAccountType.cash,
      amount: amount,
    );

void main() {
  group('the whole setup', () {
    test('the sample setup is valid', () {
      expect(_validate(sampleSetup()), isEmpty);
      expect(SetupValidator.isValid(sampleSetup(), now: setupNow), isTrue);
    });

    test('only a name is required, so every other step can be skipped', () {
      expect(_validate(_base), isEmpty);
    });

    test('an empty name is the only problem in an empty setup', () {
      final issues = _validate(const SetupData());

      expect(issues.length, 1);
      expect(issues.single.step, SetupStep.preferences);
      expect(issues.single.message, 'Enter your name');
    });

    test('problems come back in step order', () {
      final data = SetupData(
        displayName: '',
        incomes: [_income(amount: Money.zero)],
        balances: [_account('Cash', Money.taka(-5))],
      );

      expect(_steps(data), [
        SetupStep.preferences,
        SetupStep.income,
        SetupStep.balances,
      ]);
    });
  });

  group('step A: about you', () {
    test('the cycle start day must be 1 to 28', () {
      const message = 'The cycle start day must be between 1 and 28';

      expect(_messages(_base.copyWith(cycleStartDay: 0)), [message]);
      expect(_messages(_base.copyWith(cycleStartDay: 29)), [message]);
      expect(_validate(_base.copyWith(cycleStartDay: 1)), isEmpty);
      expect(_validate(_base.copyWith(cycleStartDay: 28)), isEmpty);
    });

    test('only Bangladeshi Taka is supported for now', () {
      expect(
        _messages(_base.copyWith(currencyCode: 'USD')),
        ['Only Bangladeshi Taka (BDT) is supported for now'],
      );
    });
  });

  group('step B: income', () {
    test('an amount of zero is rejected, with the source named', () {
      final data = _base.copyWith(incomes: [_income(amount: Money.zero)]);

      expect(_messages(data), ['Income "Tutoring": amount must be greater than 0']);
      expect(_steps(data), [SetupStep.income]);
    });

    test('the largest allowed amount is accepted and one paisa more is not', () {
      expect(
        _validate(_base.copyWith(incomes: [_income(amount: const Money(9999999999))])),
        isEmpty,
      );
      expect(
        _messages(_base.copyWith(incomes: [_income(amount: const Money(10000000000))])),
        ['Income "Tutoring": amount is too large'],
      );
    });

    test('the name must be 2 to 40 characters', () {
      expect(
        _messages(_base.copyWith(incomes: [_income(name: 'A')])),
        ['Income "A": name must be 2 to 40 characters'],
      );
      expect(
        _messages(_base.copyWith(incomes: [_income(name: '  ')])),
        ['Income: name must be 2 to 40 characters'],
      );
      expect(
        _validate(_base.copyWith(incomes: [_income(name: 'A' * 40)])),
        isEmpty,
      );
    });

    test('the day of month must be 1 to 28, and is optional', () {
      expect(
        _messages(_base.copyWith(incomes: [_income(day: 29)])),
        ['Income "Tutoring": day of month must be between 1 and 28'],
      );
      expect(
        _messages(_base.copyWith(incomes: [_income(day: 0)])),
        ['Income "Tutoring": day of month must be between 1 and 28'],
      );
      expect(_validate(_base.copyWith(incomes: [_income(day: null)])), isEmpty);
      expect(
        _validate(_base.copyWith(
          incomes: [_income(day: null, frequency: SetupFrequency.weekly)],
        )),
        isEmpty,
      );
    });

    test('a note over 100 characters is rejected', () {
      final data = _base.copyWith(incomes: [_income(note: 'x' * 101)]);
      expect(
        _messages(data).single,
        contains('note must be 100 characters or fewer'),
      );
    });

    test('every problem on one entry is reported', () {
      final data = _base.copyWith(
        incomes: [_income(name: 'A', amount: Money.zero)],
      );
      expect(_messages(data).length, 2);
    });
  });

  group('step C: fixed expenses', () {
    test('a monthly bill needs a due day', () {
      expect(
        _messages(_base.copyWith(fixedExpenses: [_fixed(day: null)])),
        ['Fixed expense "Rent": choose the day of the month it is due'],
      );
    });

    test('weekly and yearly expenses do not need a due day', () {
      expect(
        _validate(_base.copyWith(
          fixedExpenses: [_fixed(day: null, frequency: SetupFrequency.weekly)],
        )),
        isEmpty,
      );
      expect(
        _validate(_base.copyWith(
          fixedExpenses: [_fixed(day: null, frequency: SetupFrequency.yearly)],
        )),
        isEmpty,
      );
    });

    test('a negative amount is rejected', () {
      expect(
        _messages(_base.copyWith(fixedExpenses: [_fixed(amount: Money.taka(-5))])),
        ['Fixed expense "Rent": amount must be greater than 0'],
      );
    });

    test('an out-of-range due day is rejected', () {
      expect(
        _messages(_base.copyWith(fixedExpenses: [_fixed(day: 31)])),
        ['Fixed expense "Rent": day of month must be between 1 and 28'],
      );
    });
  });

  group('step D: spending estimates', () {
    test('zero means "not set" and is fine', () {
      expect(
        _validate(_base.copyWith(spending: {SpendingCategory.food: Money.zero})),
        isEmpty,
      );
    });

    test('a negative estimate is rejected, naming the category', () {
      expect(
        _messages(_base.copyWith(
          spending: {SpendingCategory.food: Money.taka(-1)},
        )),
        ['Food and groceries: estimate cannot be negative'],
      );
    });

    test('an enormous estimate is rejected', () {
      expect(
        _messages(_base.copyWith(
          spending: {SpendingCategory.shopping: const Money(10000000000)},
        )),
        ['Shopping: estimate is too large'],
      );
    });
  });

  group('step E: savings', () {
    test('a negative target is rejected', () {
      expect(
        _messages(_base.copyWith(
          savings: SavingsPlan(monthlyTarget: Money.taka(-100)),
        )),
        ['The monthly savings target cannot be negative'],
      );
    });

    test('a purpose without an amount is allowed', () {
      expect(
        _validate(_base.copyWith(savings: const SavingsPlan(purpose: 'Trip'))),
        isEmpty,
      );
    });

    test('a purpose over 60 characters is rejected', () {
      expect(
        _messages(_base.copyWith(
          savings: SavingsPlan(
            monthlyTarget: Money.taka(500),
            purpose: 'A' * 61,
          ),
        )),
        ['The savings purpose must be 60 characters or fewer'],
      );
    });

    test('a target date today is fine, and one in the past is not', () {
      expect(
        _validate(_base.copyWith(
          savings: SavingsPlan(
            monthlyTarget: Money.taka(500),
            targetDate: DateTime(2026, 10, 10, 9, 0),
          ),
        )),
        isEmpty,
      );
      expect(
        _messages(_base.copyWith(
          savings: SavingsPlan(
            monthlyTarget: Money.taka(500),
            targetDate: DateTime(2026, 10, 9),
          ),
        )),
        ['The savings target date cannot be in the past'],
      );
    });

    test('a target date needs a monthly amount', () {
      expect(
        _messages(_base.copyWith(
          savings: SavingsPlan(targetDate: DateTime(2026, 12, 31)),
        )),
        ['Set a monthly savings amount, or remove the target date'],
      );
    });
  });

  group('step F: opening balances', () {
    test('zero is a fine balance', () {
      expect(
        _validate(_base.copyWith(balances: [_account('Nagad', Money.zero)])),
        isEmpty,
      );
    });

    test('a negative balance is rejected', () {
      expect(
        _messages(_base.copyWith(balances: [_account('Cash', Money.taka(-5))])),
        ['Account "Cash": balance cannot be negative'],
      );
    });

    test('names must be unique, ignoring capitals and spaces', () {
      final data = _base.copyWith(
        balances: [
          _account('Cash', Money.taka(1000), id: 'a'),
          _account(' cash ', Money.taka(500), id: 'b'),
        ],
      );
      expect(
        _messages(data),
        ['Account "cash": another account already has this name'],
      );
    });

    test('different names are fine', () {
      expect(
        _validate(_base.copyWith(
          balances: [
            _account('Cash', Money.taka(1000), id: 'a'),
            _account('bKash', Money.taka(500), id: 'b'),
          ],
        )),
        isEmpty,
      );
    });

    test('the name must be 2 to 30 characters', () {
      expect(
        _messages(_base.copyWith(balances: [_account('A', Money.taka(5))])),
        ['Account "A": name must be 2 to 30 characters'],
      );
      expect(
        _messages(_base.copyWith(balances: [_account('A' * 31, Money.taka(5))])),
        hasLength(1),
      );
    });
  });
}