import 'package:flutter/widgets.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/transactions/domain/transaction_models.dart';

// An enum is a fixed set of choices. The compiler stops typos like 'recieved'.
enum IncomeStatus {
  received, // the money has arrived in an account
  expected, // the money is promised, but not here yet
}

class IncomeSource {
  const IncomeSource({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final IconData icon;
}

// What the form hands back when you tap Save.
// Later, this becomes the request sent to the server.
class NewIncome {
  const NewIncome({
    required this.amount,
    required this.source,
    required this.status,
    required this.date,
    this.account,
    this.note,
  });

  final Money amount;
  final IncomeSource source;
  final IncomeStatus status;

  /// Received: the exact date and time it arrived.
  /// Expected: the day it is expected (midnight, no time).
  final DateTime date;

  /// Where the money went. Null for expected income, because it is not in
  /// any account yet.
  final PaymentAccount? account;

  final String? note;
}