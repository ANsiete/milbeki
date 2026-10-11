import 'package:milbeki_app/core/utils/date_only.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/core/utils/validators.dart';
import 'package:milbeki_app/features/setup/domain/setup_models.dart';

// One problem found in the setup data, and the step it belongs to,
// so the review can say where to fix it.
class SetupIssue {
  const SetupIssue(this.step, this.message);

  final SetupStep step;
  final String message;
}

class SetupValidator {
  /// Returns every problem found, in step order. An empty list means the
  /// setup is valid. The server repeats these checks later.
  static List<SetupIssue> validate(SetupData data, {required DateTime now}) {
    final issues = <SetupIssue>[];
    void add(SetupStep step, String message) {
      issues.add(SetupIssue(step, message));
    }

    // Step A: about you.
    final nameError = Validators.displayName(data.displayName);
    if (nameError != null) add(SetupStep.preferences, nameError);

    if (data.cycleStartDay < 1 ||
        data.cycleStartDay > SetupLimits.maxDayOfMonth) {
      add(SetupStep.preferences, 'The cycle start day must be between 1 and 28');
    }
    if (data.currencyCode != 'BDT') {
      add(
        SetupStep.preferences,
        'Only Bangladeshi Taka (BDT) is supported for now',
      );
    }

    // Step B: income.
    for (final entry in data.incomes) {
      final label = _label('Income', entry.name);
      void check(String? problem) {
        if (problem != null) add(SetupStep.income, '$label: $problem');
      }

      check(_nameProblem(entry.name, 2, 40));
      check(_amountProblem(entry.amount));
      check(_dayProblem(entry.dayOfMonth));
      final note = entry.note;
      if (note != null && note.trim().length > 100) {
        check('note must be 100 characters or fewer');
      }
    }

    // Step C: fixed expenses.
    for (final item in data.fixedExpenses) {
      final label = _label('Fixed expense', item.title);
      void check(String? problem) {
        if (problem != null) add(SetupStep.fixedExpenses, '$label: $problem');
      }

      check(_nameProblem(item.title, 2, 40));
      check(_amountProblem(item.amount));
      check(_dayProblem(item.dayOfMonth));
      if (item.frequency == SetupFrequency.monthly && item.dayOfMonth == null) {
        check('choose the day of the month it is due');
      }
    }

    // Step D: regular spending estimates. Zero means "not set".
    data.spending.forEach((category, amount) {
      if (amount.isNegative) {
        add(SetupStep.spending, '${category.label}: estimate cannot be negative');
      } else if (amount.paisa > SetupLimits.maxAmount.paisa) {
        add(SetupStep.spending, '${category.label}: estimate is too large');
      }
    });

    // Step E: savings.
    final plan = data.savings;
    if (plan.monthlyTarget.isNegative) {
      add(SetupStep.savings, 'The monthly savings target cannot be negative');
    } else if (plan.monthlyTarget.paisa > SetupLimits.maxAmount.paisa) {
      add(SetupStep.savings, 'The monthly savings target is too large');
    }
    final purpose = plan.purpose;
    if (purpose != null && purpose.trim().length > 60) {
      add(
        SetupStep.savings,
        'The savings purpose must be 60 characters or fewer',
      );
    }
    final targetDate = plan.targetDate;
    if (targetDate != null) {
      if (targetDate.dateOnly.isBefore(now.dateOnly)) {
        add(SetupStep.savings, 'The savings target date cannot be in the past');
      }
      if (plan.monthlyTarget.paisa <= 0) {
        add(
          SetupStep.savings,
          'Set a monthly savings amount, or remove the target date',
        );
      }
    }

    // Step F: opening balances.
    final seen = <String>{};
    for (final account in data.balances) {
      final label = _label('Account', account.name);
      void check(String? problem) {
        if (problem != null) add(SetupStep.balances, '$label: $problem');
      }

      check(_nameProblem(account.name, 2, 30));
      if (account.amount.isNegative) {
        check('balance cannot be negative');
      } else if (account.amount.paisa > SetupLimits.maxAmount.paisa) {
        check('balance is too large');
      }
      final key = account.name.trim().toLowerCase();
      // Set.add returns false when the name is already in the set.
      if (key.isNotEmpty && !seen.add(key)) {
        check('another account already has this name');
      }
    }

    return issues;
  }

  static bool isValid(SetupData data, {required DateTime now}) =>
      validate(data, now: now).isEmpty;

  static String _label(String prefix, String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? prefix : '$prefix "$trimmed"';
  }

  static String? _nameProblem(String name, int min, int max) {
    final length = name.trim().length;
    if (length < min || length > max) {
      return 'name must be $min to $max characters';
    }
    return null;
  }

  static String? _amountProblem(Money amount) {
    if (amount.paisa <= 0) return 'amount must be greater than 0';
    if (amount.paisa > SetupLimits.maxAmount.paisa) return 'amount is too large';
    return null;
  }

  static String? _dayProblem(int? day) {
    if (day != null && (day < 1 || day > SetupLimits.maxDayOfMonth)) {
      return 'day of month must be between 1 and 28';
    }
    return null;
  }
}