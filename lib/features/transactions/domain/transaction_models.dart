import 'package:flutter/widgets.dart';
import 'package:milbeki_app/core/utils/money.dart';

class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final IconData icon;
}

class PaymentAccount {
  const PaymentAccount({
    required this.id,
    required this.name,
    required this.balance,
  });

  final String id;
  final String name;

  /// Shown on the form so you can see what each account holds.
  final Money balance;
}

// What the form hands back when you tap Save.
// Later, this becomes the request sent to the server.
class NewExpense {
  const NewExpense({
    required this.amount,
    required this.category,
    required this.account,
    required this.occurredAt,
    this.description,
  });

  final Money amount;
  final ExpenseCategory category;
  final PaymentAccount account;
  final DateTime occurredAt;
  final String? description;
}