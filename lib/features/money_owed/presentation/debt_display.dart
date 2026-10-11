import 'package:flutter/material.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';

// Small display helpers shared by the Money Owed screens.

String debtStatusLabel(DebtStatus status) {
  return switch (status) {
    DebtStatus.pending => 'Pending',
    DebtStatus.partiallyPaid => 'Partially paid',
    DebtStatus.paid => 'Paid',
    DebtStatus.overdue => 'Overdue',
    DebtStatus.cancelled => 'Cancelled',
  };
}

/// How much of the original amount is paid, from 0.0 to 1.0.
double debtPaidFraction(Debt debt) {
  if (debt.originalAmount.paisa <= 0) return 0.0;
  final fraction = debt.paidAmount.paisa / debt.originalAmount.paisa;
  return fraction.clamp(0.0, 1.0).toDouble();
}

// A coloured label. The words carry the meaning, not just the colour.
class DebtStatusChip extends StatelessWidget {
  const DebtStatusChip({super.key, required this.status});

  final DebtStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color background = switch (status) {
      DebtStatus.pending => scheme.surfaceContainerHighest,
      DebtStatus.partiallyPaid => scheme.primaryContainer,
      DebtStatus.paid => Colors.green.shade100,
      DebtStatus.overdue => scheme.errorContainer,
      DebtStatus.cancelled => Colors.grey.shade300,
    };
    final Color foreground = switch (status) {
      DebtStatus.pending => scheme.onSurface,
      DebtStatus.partiallyPaid => scheme.onPrimaryContainer,
      DebtStatus.paid => Colors.green.shade900,
      DebtStatus.overdue => scheme.onErrorContainer,
      DebtStatus.cancelled => Colors.grey.shade800,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        debtStatusLabel(status),
        style: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}