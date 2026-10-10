import 'package:flutter/material.dart';
import 'package:milbeki_app/features/transactions/data/mock_lookups.dart';
import 'package:milbeki_app/features/transactions/domain/transaction_models.dart';
import 'package:milbeki_app/features/transactions/presentation/add_expense_screen.dart';

// Opens the form and shows a message when it comes back with an expense.
// Nothing is stored yet: saving to the server is built in a later phase.
Future<void> openAddExpense(BuildContext context) async {
  // Grab these now, before the await, while the context is still valid.
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  // await pauses here until the form closes. A cancelled form returns null.
  final expense = await navigator.push<NewExpense>(
    MaterialPageRoute(
      builder: (_) => AddExpenseScreen(
        categories: MockLookups.expenseCategories,
        accounts: MockLookups.accounts,
      ),
    ),
  );

  if (expense == null) return;

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        'Recorded ${expense.amount.format()} for ${expense.category.name} '
        'from ${expense.account.name}. (Sample only: nothing is stored yet.)',
      ),
    ),
  );
}