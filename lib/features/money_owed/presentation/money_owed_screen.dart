import 'package:flutter/material.dart';
import 'package:milbeki_app/core/utils/date_format.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/core/widgets/money_text.dart';
import 'package:milbeki_app/features/money_owed/application/debt_store.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_rules.dart';
import 'package:milbeki_app/features/money_owed/presentation/add_debt_flow.dart';
import 'package:milbeki_app/features/money_owed/presentation/debt_detail_screen.dart';
import 'package:milbeki_app/features/money_owed/presentation/debt_display.dart';

// The Money Owed tab. The debts live in the shared DebtStore, so this screen
// and the Home dashboard always show the same numbers.
class MoneyOwedScreen extends StatefulWidget {
  const MoneyOwedScreen({super.key, required this.store, required this.now});

  final DebtStore store;

  /// The clock. The sample app passes a fixed date.
  final DateTime Function() now;

  @override
  State<MoneyOwedScreen> createState() => _MoneyOwedScreenState();
}

class _MoneyOwedScreenState extends State<MoneyOwedScreen> {
  DebtDirection _direction = DebtDirection.youOwe;
  DebtStatus? _statusFilter; // null means "All"
  DebtSort _sort = DebtSort.dueDate;
  String _search = '';

  void _open(Debt debt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DebtDetailScreen(
          debt: debt,
          now: widget.now,
          onChanged: widget.store.replace,
        ),
      ),
    );
  }

  void _addDebt() {
    openAddDebt(context, store: widget.store, now: widget.now);
  }

  String _emptyMessage(List<Debt> debts) {
    final anyInDirection = debts.any((d) => d.direction == _direction);
    if (!anyInDirection) {
      return _direction == DebtDirection.youOwe
          ? 'You do not owe anyone right now.'
          : 'Nobody owes you money right now.';
    }
    return 'No debts match your search or filter.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      // ListenableBuilder rebuilds this part whenever the store changes.
      child: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final debts = widget.store.debts;
          final today = widget.now();
          final summary = DebtSummary.of(debts, today: today);
          final visible = DebtRules.filter(
            debts,
            today: today,
            direction: _direction,
            status: _statusFilter,
            search: _search,
            sort: _sort,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Money Owed',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('addDebtButton'),
                    onPressed: _addDebt,
                    icon: const Icon(Icons.add),
                    label: const Text('Add debt'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TotalCard(
                      key: const Key('youOweCard'),
                      label: 'You owe',
                      total: summary.youOweTotal,
                      overdue: summary.youOweOverdue,
                      icon: Icons.call_made,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TotalCard(
                      key: const Key('owedToYouCard'),
                      label: 'Others owe you',
                      total: summary.owedToYouTotal,
                      overdue: summary.owedToYouOverdue,
                      icon: Icons.call_received,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'These are two separate totals. Money others owe you is not in '
                'your accounts until you receive it.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Due in the next 7 days',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      if (summary.dueSoon.isEmpty)
                        const Text('Nothing due in the next 7 days.')
                      else
                        for (final debt in summary.dueSoon)
                          ListTile(
                            key: Key('dueSoon-${debt.id}'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              debt.direction == DebtDirection.youOwe
                                  ? Icons.call_made
                                  : Icons.call_received,
                            ),
                            title: Text(debt.personName),
                            subtitle: Text(
                              '${debt.direction == DebtDirection.youOwe ? 'You pay' : 'Pays you'}'
                              ' · due ${AppDates.shortDate(debt.dueDate)}',
                            ),
                            trailing: MoneyText(
                              debt.outstanding,
                              colorNegative: false,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onTap: () => _open(debt),
                          ),
                      const Divider(height: 24),
                      Text(
                        '${summary.partiallySettledCount} partially settled',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<DebtDirection>(
                key: const Key('directionToggle'),
                expandedInsets: EdgeInsets.zero,
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: DebtDirection.youOwe,
                    label: Text('You owe'),
                  ),
                  ButtonSegment(
                    value: DebtDirection.owedToYou,
                    label: Text('Owed to you'),
                  ),
                ],
                selected: {_direction},
                onSelectionChanged: (selection) =>
                    setState(() => _direction = selection.first),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('debtSearchField'),
                decoration: const InputDecoration(
                  labelText: 'Search by name',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    key: const Key('filter-all'),
                    label: const Text('All'),
                    showCheckmark: false,
                    selected: _statusFilter == null,
                    onSelected: (_) => setState(() => _statusFilter = null),
                  ),
                  for (final status in DebtStatus.values)
                    ChoiceChip(
                      key: Key('filter-${status.name}'),
                      label: Text(debtStatusLabel(status)),
                      showCheckmark: false,
                      selected: _statusFilter == status,
                      onSelected: (_) => setState(() => _statusFilter = status),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Sort by', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              SegmentedButton<DebtSort>(
                key: const Key('sortToggle'),
                expandedInsets: EdgeInsets.zero,
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: DebtSort.dueDate,
                    label: Text('Due date'),
                  ),
                  ButtonSegment(value: DebtSort.amount, label: Text('Amount')),
                ],
                selected: {_sort},
                onSelectionChanged: (selection) =>
                    setState(() => _sort = selection.first),
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    _emptyMessage(debts),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              else
                for (final debt in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DebtCard(
                      key: Key('debtCard-${debt.id}'),
                      debt: debt,
                      today: today,
                      onTap: () => _open(debt),
                    ),
                  ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    super.key,
    required this.label,
    required this.total,
    required this.overdue,
    required this.icon,
  });

  final String label;
  final Money total;
  final Money overdue;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
              ],
            ),
            const SizedBox(height: 6),
            MoneyText(
              total,
              colorNegative: false,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (overdue.paisa > 0)
              Text(
                'Overdue ${overdue.format()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text('Nothing overdue', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({
    super.key,
    required this.debt,
    required this.today,
    required this.onTap,
  });

  final Debt debt;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = debt.statusOn(today);
    final description = debt.description;

    final String dueText = switch (status) {
      DebtStatus.overdue => 'Overdue since ${AppDates.shortDate(debt.dueDate)}',
      DebtStatus.paid => 'Settled',
      DebtStatus.cancelled =>
        'Cancelled ${AppDates.shortDate(debt.cancelledAt!)}',
      DebtStatus.pending ||
      DebtStatus.partiallyPaid =>
        'Due ${AppDates.shortDate(debt.dueDate)}',
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      debt.personName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DebtStatusChip(status: status),
                ],
              ),
              const SizedBox(height: 8),
              MoneyText(
                debt.outstanding,
                colorNegative: false,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'left of ${debt.originalAmount.format()}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: debtPaidFraction(debt),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Text(
                dueText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: status == DebtStatus.overdue
                      ? theme.colorScheme.error
                      : null,
                ),
              ),
              if (description != null)
                Text(description, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}