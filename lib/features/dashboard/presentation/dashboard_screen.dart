import 'package:flutter/material.dart';
import 'package:milbeki_app/core/utils/date_format.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/core/widgets/budget_progress.dart';
import 'package:milbeki_app/core/widgets/money_text.dart';
import 'package:milbeki_app/features/dashboard/domain/daily_limit.dart';
import 'package:milbeki_app/features/dashboard/domain/dashboard_models.dart';
import 'package:milbeki_app/features/dashboard/presentation/daily_limit_card.dart';

// The Home tab. It only displays; every number comes from DashboardData
// and from DailyLimitCalculator, which has its own tests.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final limit = DailyLimitCalculator.calculate(
      moneyHeld: data.moneyHeld,
      dueItems: data.dueItems,
      savingsRemaining: data.savingsRemaining,
      spentToday: data.spentToday,
      cycle: data.cycle,
      today: data.now,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hello, ${data.userName}',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              AppDates.weekdayDate(data.now),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const _QuickActions(),
            const SizedBox(height: 16),
            _PositionCard(data: data, daysLeft: limit.daysLeft),
            const SizedBox(height: 12),
            DailyLimitCard(limit: limit),
            const SizedBox(height: 12),
            _BudgetCard(data: data),
            const SizedBox(height: 12),
            _TodayCard(data: data),
            const SizedBox(height: 12),
            _UpcomingCard(data: data),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  void _comingLater(BuildContext context, String label) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text('$label is built in a later step.')),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => _comingLater(context, label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(context, Icons.north_east, 'Expense'),
        _chip(context, Icons.south_west, 'Income'),
        _chip(context, Icons.swap_horiz, 'Lend / Borrow'),
        _chip(context, Icons.event_repeat, 'Bill'),
      ],
    );
  }
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({required this.data, required this.daysLeft});

  final DashboardData data;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Money you hold', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            MoneyText(
              data.moneyHeld,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'In your accounts right now. Money other people owe you is not included.',
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Income this cycle',
                    amount: data.periodIncome,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Spent this cycle',
                    amount: data.periodExpenses,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${AppDates.shortDate(data.cycle.start)} to '
              '${AppDates.shortDate(data.cycle.end)} · '
              '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.amount});

  final String label;
  final Money amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        MoneyText(
          amount,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = data.monthlyBudget - data.periodExpenses;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Monthly budget',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            BudgetProgress(
              label: 'All spending',
              spent: data.periodExpenses,
              budget: data.monthlyBudget,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Remaining'),
                const Spacer(),
                MoneyText(
                  remaining,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('By category', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            for (final category in data.categories)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BudgetProgress(
                  label: category.name,
                  spent: category.spent,
                  budget: category.budget,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Copy the list, then sort the copy: newest first.
    final expenses = [...data.todayExpenses]
      ..sort((a, b) => b.time.compareTo(a.time));
    final count = expenses.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Spent today', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            MoneyText(
              data.spentToday,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '$count ${count == 1 ? 'transaction' : 'transactions'}',
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 24),
            if (expenses.isEmpty) const Text('Nothing spent today yet.'),
            for (final expense in expenses)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  radius: 18,
                  child: Icon(Icons.receipt_long, size: 18),
                ),
                title: Text(expense.title),
                subtitle: Text(
                  '${expense.categoryName} · ${AppDates.time12h(expense.time)}',
                ),
                trailing: MoneyText(
                  expense.amount,
                  colorNegative: false,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime(data.now.year, data.now.month, data.now.day);

    final items = [...data.dueItems]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Upcoming',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty) const Text('Nothing coming up.'),
            for (final item in items) _dueTile(theme, item, today),
          ],
        ),
      ),
    );
  }

  Widget _dueTile(ThemeData theme, DueItem item, DateTime today) {
    final dueDay = DateTime(
      item.dueDate.year,
      item.dueDate.month,
      item.dueDate.day,
    );
    final isOverdue = dueDay.isBefore(today);
    final date = AppDates.shortDate(item.dueDate);

    final IconData icon = switch (item.kind) {
      DueKind.bill => Icons.receipt_long,
      DueKind.debtYouOwe => Icons.call_made,
      DueKind.owedToYou => Icons.call_received,
    };

    final String subtitle;
    if (item.kind == DueKind.owedToYou) {
      subtitle = isOverdue
          ? 'Was expected $date. Not received yet.'
          : 'Expected $date. Not received yet.';
    } else {
      subtitle = isOverdue ? 'Overdue since $date' : 'Due $date';
    }

    final Widget trailing;
    if (item.kind == DueKind.owedToYou) {
      // A plus sign: this money is coming to you, but is not in your pocket yet.
      trailing = Text(
        '+${item.amount.format()}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      );
    } else {
      trailing = MoneyText(
        item.amount,
        colorNegative: false,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(radius: 18, child: Icon(icon, size: 18)),
      title: Text(item.title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: isOverdue ? theme.colorScheme.error : null),
      ),
      trailing: trailing,
    );
  }
}