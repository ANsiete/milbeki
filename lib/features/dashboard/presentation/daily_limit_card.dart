import 'package:flutter/material.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/core/widgets/money_text.dart';
import 'package:milbeki_app/features/dashboard/domain/daily_limit.dart';

// The most important card on the dashboard: how much you can safely spend today.
class DailyLimitCard extends StatelessWidget {
  const DailyLimitCard({super.key, required this.limit});

  final DailyLimit limit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textColor = colors.onPrimaryContainer;
    final isOver = limit.remainingToday.isNegative;

    final String statusLine;
    if (limit.isShortfall) {
      statusLine =
          'Your commitments are ${limit.shortfall.format()} more than the money you hold.';
    } else if (isOver) {
      statusLine =
          "Over today's limit by ${Money(-limit.remainingToday.paisa).format()}";
    } else {
      statusLine = '${limit.remainingToday.format()} left today';
    }

    final days = limit.daysLeft;

    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Safe to spend today',
              style: theme.textTheme.labelLarge?.copyWith(color: textColor),
            ),
            const SizedBox(height: 4),
            MoneyText(
              limit.dailyLimit,
              colorNegative: false,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              statusLine,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: (limit.isShortfall || isOver) ? colors.error : textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$days ${days == 1 ? 'day' : 'days'} left in this cycle',
              style: theme.textTheme.bodySmall?.copyWith(color: textColor),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => showDailyLimitExplanation(context, limit),
                child: const Text('How is this calculated?'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A panel that shows every number behind the limit, so it is never a mystery.
Future<void> showDailyLimitExplanation(BuildContext context, DailyLimit limit) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How your daily limit is calculated',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _CalcRow('Money in your accounts', limit.moneyHeld.format()),
              _CalcRow('Bills due by cycle end', '-${limit.billsDue.format()}'),
              _CalcRow(
                'Debts you owe, due by cycle end',
                '-${limit.debtsDue.format()}',
              ),
              _CalcRow(
                'Savings still to set aside',
                '-${limit.savingsReserved.format()}',
              ),
              const Divider(),
              _CalcRow(
                'Spendable after commitments',
                limit.spendable.format(),
                bold: true,
              ),
              _CalcRow(
                "Add back today's spending",
                '+${limit.spentToday.format()}',
              ),
              const Divider(),
              _CalcRow(
                'Amount at the start of today',
                limit.startOfDay.format(),
                bold: true,
              ),
              _CalcRow('Days left, including today', '${limit.daysLeft}'),
              const Divider(),
              _CalcRow(
                'Your daily limit (rounded down)',
                limit.dailyLimit.format(),
                bold: true,
              ),
              const SizedBox(height: 12),
              Text(
                'Money other people owe you is never counted until you actually '
                'receive it. These are estimates based on the bills and debts '
                'you have recorded.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _CalcRow extends StatelessWidget {
  const _CalcRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}