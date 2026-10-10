import 'package:flutter/material.dart';
import 'package:milbeki_app/core/utils/money.dart';

/// Whole-number percent of the budget used. It is not capped, so 150 means
/// 50% over budget. A zero budget counts as 100% used if anything was spent.
int budgetPercent(Money spent, Money budget) {
  if (budget.paisa <= 0) return spent.paisa > 0 ? 100 : 0;
  return (spent.paisa * 100) ~/ budget.paisa;
}

enum BudgetStatus { ok, nearLimit, over }

/// 80% or more is a warning. Over 100% is over budget.
BudgetStatus budgetStatus(int percent) {
  if (percent > 100) return BudgetStatus.over;
  if (percent >= 80) return BudgetStatus.nearLimit;
  return BudgetStatus.ok;
}

// A label, "spent of budget", a progress bar, and a status message.
class BudgetProgress extends StatelessWidget {
  const BudgetProgress({
    super.key,
    required this.label,
    required this.spent,
    required this.budget,
  });

  final String label;
  final Money spent;
  final Money budget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = budgetPercent(spent, budget);
    final status = budgetStatus(percent);

    // A switch expression picks one value per case.
    final Color color = switch (status) {
      BudgetStatus.ok => theme.colorScheme.primary,
      BudgetStatus.nearLimit => Colors.orange.shade800,
      BudgetStatus.over => theme.colorScheme.error,
    };
    final String message = switch (status) {
      BudgetStatus.ok => '$percent% used',
      BudgetStatus.nearLimit => '$percent% used. Close to the limit.',
      BudgetStatus.over => 'Over budget by ${(spent - budget).format()}.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: theme.textTheme.titleSmall),
            ),
            Text(
              '${spent.format()} of ${budget.format()}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          // The bar stops at full even when spending is over budget.
          value: (percent / 100).clamp(0.0, 1.0).toDouble(),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          color: color,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 4),
        Text(
          message,
          style: theme.textTheme.bodySmall?.copyWith(
            color: status == BudgetStatus.ok ? null : color,
          ),
        ),
      ],
    );
  }
}