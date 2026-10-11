import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/setup/domain/setup_calculations.dart';
import 'package:milbeki_app/features/setup/domain/setup_models.dart';

import 'support/setup_scenario.dart';

void main() {
  group('monthlyEquivalent', () {
    test('monthly amounts are unchanged', () {
      expect(
        monthlyEquivalent(Money.taka(5000), SetupFrequency.monthly),
        Money.taka(5000),
      );
    });

    test('weekly is multiplied by 52 and divided by 12', () {
      // 1,200 * 52 / 12 = 5,200 exactly.
      expect(
        monthlyEquivalent(Money.taka(1200), SetupFrequency.weekly),
        Money.taka(5200),
      );
    });

    test('weekly rounds down to the paisa', () {
      // 500 * 52 / 12 = 2,166.666..., kept as 2,166.66.
      final result = monthlyEquivalent(Money.taka(500), SetupFrequency.weekly);
      expect(result, const Money(216666));
      expect(result.format(), '৳2,166.66');
    });

    test('yearly is divided by 12', () {
      expect(
        monthlyEquivalent(Money.taka(12000), SetupFrequency.yearly),
        Money.taka(1000),
      );
    });

    test('yearly rounds down to the paisa', () {
      // 1,001 / 12 = 83.4166..., kept as 83.41.
      final result = monthlyEquivalent(Money.taka(1001), SetupFrequency.yearly);
      expect(result, const Money(8341));
      expect(result.format(), '৳83.41');
    });
  });

  group('SetupOverview', () {
    test('the sample setup gives the worked numbers', () {
      final overview = SetupOverview.of(sampleSetup());

      expect(overview.expectedMonthlyIncome, Money.taka(14000));
      expect(overview.fixedExpenses, Money.taka(6650));
      expect(overview.fixedStillToPay, Money.taka(6000)); // rent + internet
      expect(overview.variableExpenses, Money.taka(4720));
      expect(overview.savingsTarget, Money.taka(2000));
      expect(overview.estimatedRemaining, Money.taka(630));
      expect(overview.moneyHeld, Money.taka(14600));
      expect(overview.isShortfall, isFalse);
      expect(overview.shortfall, Money.zero);
    });

    test('an empty setup is all zeros and not a shortfall', () {
      final overview = SetupOverview.of(const SetupData());

      expect(overview.expectedMonthlyIncome, Money.zero);
      expect(overview.fixedExpenses, Money.zero);
      expect(overview.fixedStillToPay, Money.zero);
      expect(overview.variableExpenses, Money.zero);
      expect(overview.savingsTarget, Money.zero);
      expect(overview.estimatedRemaining, Money.zero);
      expect(overview.moneyHeld, Money.zero);
      expect(overview.isShortfall, isFalse);
    });

    test('opening balances are not income and do not change the remaining amount', () {
      final withBalances = SetupOverview.of(sampleSetup());
      final withoutBalances =
          SetupOverview.of(sampleSetup().copyWith(balances: const []));

      expect(withoutBalances.moneyHeld, Money.zero);
      expect(withBalances.moneyHeld, Money.taka(14600));
      expect(
        withBalances.expectedMonthlyIncome,
        withoutBalances.expectedMonthlyIncome,
      );
      expect(withBalances.estimatedRemaining, Money.taka(630));
      expect(withoutBalances.estimatedRemaining, Money.taka(630));
    });

    test('weekly income counts as a monthly estimate', () {
      final base = sampleSetup();
      final data = base.copyWith(
        incomes: [
          ...base.incomes,
          IncomeEntry(
            id: 'inc-weekly',
            name: 'Part-time job',
            amount: Money.taka(1200),
            frequency: SetupFrequency.weekly,
          ),
        ],
      );
      final overview = SetupOverview.of(data);

      expect(overview.expectedMonthlyIncome, Money.taka(19200)); // 14,000 + 5,200
      expect(overview.estimatedRemaining, Money.taka(5830)); // 19,200 - 6,650 - 4,720 - 2,000
    });

    test('income is rounded down, so the estimate never overstates it', () {
      final data = SetupData(
        incomes: [
          IncomeEntry(
            id: 'w',
            name: 'Part-time job',
            amount: Money.taka(500),
            frequency: SetupFrequency.weekly,
          ),
        ],
      );
      expect(SetupOverview.of(data).expectedMonthlyIncome, const Money(216666));
    });

    test('a yearly expense counts one twelfth, and unpaid ones are still to pay', () {
      final base = sampleSetup();
      final data = base.copyWith(
        fixedExpenses: [
          ...base.fixedExpenses,
          FixedExpenseEntry(
            id: 'fx-annual',
            kind: FixedExpenseKind.education,
            title: 'Annual fee',
            amount: Money.taka(12000),
            frequency: SetupFrequency.yearly,
          ),
        ],
      );
      final overview = SetupOverview.of(data);

      expect(overview.fixedExpenses, Money.taka(7650)); // 6,650 + 1,000
      expect(overview.fixedStillToPay, Money.taka(7000)); // 6,000 + 1,000
    });

    test('a paid expense counts in the monthly estimate but not in "still to pay"', () {
      final overview = SetupOverview.of(sampleSetup());

      // Electricity (650) is marked paid.
      expect(overview.fixedExpenses.paisa - overview.fixedStillToPay.paisa, 65000);
    });

    test('a shortfall is shown, not hidden', () {
      final data = SetupData(
        displayName: 'Ashraf',
        incomes: [
          IncomeEntry(id: 'i', name: 'Allowance', amount: Money.taka(5000)),
        ],
        fixedExpenses: [
          FixedExpenseEntry(
            id: 'f',
            kind: FixedExpenseKind.rent,
            title: 'Rent',
            amount: Money.taka(6000),
            dayOfMonth: 5,
          ),
        ],
      );
      final overview = SetupOverview.of(data);

      expect(overview.estimatedRemaining, Money.taka(-1000));
      expect(overview.isShortfall, isTrue);
      expect(overview.shortfall, Money.taka(1000));
    });

    test('exactly enough is zero remaining and not a shortfall', () {
      final data = SetupData(
        incomes: [
          IncomeEntry(id: 'i', name: 'Allowance', amount: Money.taka(5000)),
        ],
        savings: SavingsPlan(monthlyTarget: Money.taka(5000)),
      );
      final overview = SetupOverview.of(data);

      expect(overview.estimatedRemaining, Money.zero);
      expect(overview.isShortfall, isFalse);
    });
  });

  test('copyWith changes only what it is given', () {
    final original = sampleSetup();
    final changed = original.copyWith(displayName: 'Rahim');

    expect(changed.displayName, 'Rahim');
    expect(changed.cycleStartDay, original.cycleStartDay);
    expect(changed.incomes.length, 2);
    expect(changed.balances.length, 2);
    expect(original.displayName, 'Ashraf'); // the original is untouched
  });
}