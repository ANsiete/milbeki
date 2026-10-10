import 'package:flutter/material.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/transactions/domain/transaction_models.dart';

// Sample categories and accounts. The server provides these later.
// Account balances add up to the ৳14,600 on the dashboard.
class MockLookups {
  static const List<ExpenseCategory> expenseCategories = [
    ExpenseCategory(id: 'food', name: 'Food', icon: Icons.restaurant),
    ExpenseCategory(
      id: 'groceries',
      name: 'Groceries',
      icon: Icons.shopping_basket,
    ),
    ExpenseCategory(id: 'snacks', name: 'Snacks', icon: Icons.fastfood),
    ExpenseCategory(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_bus,
    ),
    ExpenseCategory(id: 'rent', name: 'House Rent', icon: Icons.home),
    ExpenseCategory(id: 'utilities', name: 'Utilities', icon: Icons.bolt),
    ExpenseCategory(id: 'internet', name: 'Internet', icon: Icons.wifi),
    ExpenseCategory(id: 'mobile', name: 'Mobile', icon: Icons.phone_android),
    ExpenseCategory(id: 'education', name: 'Education', icon: Icons.school),
    ExpenseCategory(
      id: 'health',
      name: 'Health',
      icon: Icons.local_hospital,
    ),
    ExpenseCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag,
    ),
    ExpenseCategory(id: 'fun', name: 'Entertainment', icon: Icons.movie),
    ExpenseCategory(id: 'other', name: 'Other', icon: Icons.more_horiz),
  ];

  // Money(paisa): 260000 paisa is ৳2,600.
  static const List<PaymentAccount> accounts = [
    PaymentAccount(id: 'cash', name: 'Cash', balance: Money(260000)),
    PaymentAccount(id: 'bkash', name: 'bKash', balance: Money(1200000)),
    PaymentAccount(id: 'nagad', name: 'Nagad', balance: Money(0)),
  ];
}