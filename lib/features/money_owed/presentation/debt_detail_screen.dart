import 'package:flutter/material.dart';
import 'package:milbeki_app/core/utils/date_format.dart';
import 'package:milbeki_app/core/widgets/money_text.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';
import 'package:milbeki_app/features/money_owed/presentation/add_payment_screen.dart';
import 'package:milbeki_app/features/money_owed/presentation/debt_display.dart';

// One debt in detail: the amounts, the payment history, and the button to
// record a payment. It tells the list screen about changes through onChanged.
class DebtDetailScreen extends StatefulWidget {
  const DebtDetailScreen({
    super.key,
    required this.debt,
    required this.now,
    required this.onChanged,
  });

  final Debt debt;
  final DateTime Function() now;
  final void Function(Debt updated) onChanged;

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  late Debt _debt;

  @override
  void initState() {
    super.initState();
    _debt = widget.debt;
  }

  Future<void> _recordPayment() async {
    // Grab these now, before the await, while the context is still valid.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final payment = await navigator.push<DebtPayment>(
      MaterialPageRoute(
        builder: (_) => AddPaymentScreen(debt: _debt, now: widget.now),
      ),
    );
    if (payment == null || !mounted) return;

    // withPayment returns a NEW debt. The old one is left unchanged.
    final updated = _debt.withPayment(payment);
    setState(() => _debt = updated);
    widget.onChanged(updated);

    final left = updated.outstanding.paisa > 0
        ? 'Outstanding is now ${updated.outstanding.format()}.'
        : 'Fully paid.';
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Recorded ${payment.amount.format()}. $left '
          '(Sample only: nothing is stored yet.)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _debt.statusOn(widget.now());
    final youOwe = _debt.direction == DebtDirection.youOwe;
    final description = _debt.description;
    final cancelledAt = _debt.cancelledAt;

    // Newest payment first. A tie falls back to the id, so the order is stable.
    final payments = [..._debt.payments]..sort((a, b) {
        final byTime = b.paidAt.compareTo(a.paidAt);
        return byTime != 0 ? byTime : b.id.compareTo(a.id);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Debt details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      youOwe
                          ? 'You owe ${_debt.personName}'
                          : '${_debt.personName} owes you',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DebtStatusChip(status: status),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Outstanding', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 4),
                      MoneyText(
                        _debt.outstanding,
                        key: const Key('outstandingAmount'),
                        colorNegative: false,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: debtPaidFraction(_debt),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Paid ${_debt.paidAmount.format()} of '
                        '${_debt.originalAmount.format()}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Started',
                        value: AppDates.shortDate(_debt.startDate),
                      ),
                      _DetailRow(
                        label: 'Due',
                        value: status == DebtStatus.overdue
                            ? 'Overdue since ${AppDates.shortDate(_debt.dueDate)}'
                            : AppDates.shortDate(_debt.dueDate),
                        warn: status == DebtStatus.overdue,
                      ),
                      if (description != null)
                        _DetailRow(label: 'Reason', value: description),
                      if (cancelledAt != null)
                        _DetailRow(
                          label: 'Cancelled',
                          value: AppDates.shortDate(cancelledAt),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_debt.isActive)
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    key: const Key('recordPaymentButton'),
                    onPressed: _recordPayment,
                    icon: const Icon(Icons.add),
                    label: Text(
                      youOwe
                          ? 'Record a payment I made'
                          : 'Record a payment I received',
                    ),
                  ),
                )
              else
                Text(
                  _debt.isCancelled
                      ? 'This debt was cancelled. No more payments can be recorded.'
                      : 'This debt is fully paid.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              const SizedBox(height: 24),
              Text(
                youOwe ? 'Payments you made' : 'Payments you received',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (payments.isEmpty) const Text('No payments yet.'),
              for (final payment in payments) _paymentTile(payment),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentTile(DebtPayment payment) {
    final when =
        '${AppDates.weekdayDate(payment.paidAt)} · ${AppDates.time12h(payment.paidAt)}';
    final extra = [
      if (payment.reference != null) 'Ref: ${payment.reference}',
      if (payment.note != null) payment.note!,
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      isThreeLine: extra.isNotEmpty,
      leading: const CircleAvatar(
        radius: 18,
        child: Icon(Icons.payments_outlined, size: 18),
      ),
      title: MoneyText(
        payment.amount,
        colorNegative: false,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(extra.isEmpty ? when : '$when\n$extra'),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.warn = false});

  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: warn ? theme.colorScheme.error : null),
            ),
          ),
        ],
      ),
    );
  }
}