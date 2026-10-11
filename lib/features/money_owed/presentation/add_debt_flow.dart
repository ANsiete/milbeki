import 'package:flutter/material.dart';
import 'package:milbeki_app/core/utils/date_format.dart';
import 'package:milbeki_app/features/money_owed/application/debt_store.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';
import 'package:milbeki_app/features/money_owed/presentation/add_debt_screen.dart';

// Opens the form, adds the new debt to the shared store, and shows a message.
// Nothing is saved to disk yet: saving to the server is built in a later phase.
Future<void> openAddDebt(
  BuildContext context, {
  required DebtStore store,
  required DateTime Function() now,
}) async {
  // Grab these now, before the await, while the context is still valid.
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  // await pauses here until the form closes. A cancelled form returns null.
  final debt = await navigator.push<Debt>(
    MaterialPageRoute(builder: (_) => AddDebtScreen(now: now)),
  );
  if (debt == null) return;

  store.add(debt);

  final what = debt.direction == DebtDirection.youOwe
      ? 'You owe ${debt.personName} ${debt.originalAmount.format()}'
      : '${debt.personName} owes you ${debt.originalAmount.format()}';

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        'Recorded: $what, due ${AppDates.shortDate(debt.dueDate)}. '
        '(Sample only: nothing is stored yet. Account balances are unchanged.)',
      ),
    ),
  );
}