import 'package:flutter/material.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/core/widgets/money_text.dart';
import 'package:milbeki_app/core/widgets/summary_card.dart';

class ComponentGalleryScreen extends StatelessWidget {
  const ComponentGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Numbers from our Phase 1 worked example.
    final cash = Money.taka(2600);
    final bkash = Money.taka(12000);
    final totalHeld = cash + bkash;

    final examples = [
      Money.parse('125000.5'),
      Money.taka(1234567),
      Money.taka(-1200),
      Money.zero,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Component gallery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SummaryCard(
            title: 'Total money you hold',
            amount: totalHeld,
            subtitle: 'Cash + bKash',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: 'Income this period',
            amount: Money.taka(10000),
            icon: Icons.south_west,
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: 'Expenses this period',
            amount: Money.taka(500),
            icon: Icons.north_east,
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: 'You owe',
            amount: Money.taka(300),
            subtitle: 'Fatir',
            icon: Icons.call_made,
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: 'Others owe you',
            amount: Money.taka(200),
            subtitle: 'Rahim',
            icon: Icons.call_received,
          ),
          const SizedBox(height: 24),
          Text(
            'Formatting examples',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final money in examples) MoneyText(money),
        ],
      ),
    );
  }
}