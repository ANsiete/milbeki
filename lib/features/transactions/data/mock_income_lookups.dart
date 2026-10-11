import 'package:flutter/material.dart';
import 'package:milbeki_app/features/transactions/domain/income_models.dart';

// Sample income sources. The server provides these later.
// There is deliberately no "Loan" or "Repayment" source: borrowed money and
// repayments are recorded under Money Owed, so they never count as income.
class MockIncomeLookups {
  static const List<IncomeSource> sources = [
    IncomeSource(
      id: 'allowance',
      name: 'Family allowance',
      icon: Icons.family_restroom,
    ),
    IncomeSource(id: 'salary', name: 'Salary', icon: Icons.work),
    IncomeSource(id: 'tutoring', name: 'Tutoring', icon: Icons.menu_book),
    IncomeSource(id: 'freelancing', name: 'Freelancing', icon: Icons.laptop),
    IncomeSource(id: 'business', name: 'Business', icon: Icons.store),
    IncomeSource(id: 'gift', name: 'Gift', icon: Icons.card_giftcard),
    IncomeSource(id: 'other', name: 'Other', icon: Icons.more_horiz),
  ];
}