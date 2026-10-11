import 'package:flutter/material.dart';
import 'package:milbeki_app/core/utils/date_format.dart';
import 'package:milbeki_app/features/transactions/data/mock_income_lookups.dart';
import 'package:milbeki_app/features/transactions/data/mock_lookups.dart';
import 'package:milbeki_app/features/transactions/domain/income_models.dart';
import 'package:milbeki_app/features/transactions/presentation/add_income_screen.dart';

// Opens the form and shows a message when it comes back with an income.
// Nothing is stored yet: saving to the server is built in a later phase.
Future<void> openAddIncome(BuildContext context) async {
  // Grab these now, before the await, while the context is still valid.
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  // await pauses here until the form closes. A cancelled form returns null.
  final income = await navigator.push<NewIncome>(
    MaterialPageRoute(
      builder: (_) => AddIncomeScreen(
        sources: MockIncomeLookups.sources,
        accounts: MockLookups.accounts,
      ),
    ),
  );
  if (income == null) return;

  final String text;
  if (income.status == IncomeStatus.received) {
    final accountName = income.account?.name ?? 'your account';
    text = 'Recorded ${income.amount.format()} from ${income.source.name} '
        'into $accountName. (Sample only: nothing is stored yet.)';
  } else {
    text = 'Noted: ${income.amount.format()} expected from '
        '${income.source.name} on ${AppDates.shortDate(income.date)}. '
        'It is not counted until you receive it. '
        '(Sample only: nothing is stored yet.)';
  }

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(text)));
}