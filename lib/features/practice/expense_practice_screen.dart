import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// A StatefulWidget has two parts: this widget, and a State class below it
// that holds the data which can change.
class ExpensePracticeScreen extends StatefulWidget {
  const ExpensePracticeScreen({super.key});

  @override
  State<ExpensePracticeScreen> createState() => _ExpensePracticeScreenState();
}

class _ExpensePracticeScreenState extends State<ExpensePracticeScreen> {
  // Controllers let us read (and clear) what the user typed in a text field.
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  // The data this screen remembers.
  final List<_PracticeExpense> _expenses = [];
  String? _errorText;

  // A getter: a value calculated from the list every time it is read.
  // We never store the total separately, so it can never disagree with the list.
  int get _total => _expenses.fold<int>(0, (sum, e) => sum + e.amount);

  // Controllers must be released when the screen goes away.
  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addExpense() {
    final amount = int.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Enter a whole amount greater than 0');
      return;
    }

    final note = _noteController.text.trim();

    // Everything inside setState() is a change; Flutter then rebuilds the screen.
    setState(() {
      _expenses.insert(
        0, // newest first
        _PracticeExpense(
          amount: amount,
          note: note.isEmpty ? 'Expense' : note,
          time: DateTime.now(),
        ),
      );
      _errorText = null;
    });

    _amountController.clear();
    _noteController.clear();
  }

  void _removeExpense(int index) {
    setState(() => _expenses.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Practice: spending')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
            Card(
              color: colors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Spent in this session'),
                    Text(
                      '৳$_total',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Entry row: two text fields share the width, then a button.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    key: const Key('amountField'),
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Amount (৳)',
                      border: const OutlineInputBorder(),
                      errorText: _errorText,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextField(
                    key: const Key('noteField'),
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'What for?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('addButton'),
                onPressed: _addExpense,
                icon: const Icon(Icons.add),
                label: const Text('Add expense'),
              ),
            ),
            const SizedBox(height: 16),

            // The list takes all remaining height.
            Expanded(
              child: _expenses.isEmpty
                  ? const Center(child: Text('No expenses yet. Add your first one!'))
                  : ListView.builder(
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        final expense = _expenses[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.receipt_long),
                          ),
                          title: Text(expense.note),
                          subtitle: Text(
                            TimeOfDay.fromDateTime(expense.time).format(context),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '৳${expense.amount}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeExpense(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// A small data class. The leading underscore makes it private to this file.
class _PracticeExpense {
  const _PracticeExpense({
    required this.amount,
    required this.note,
    required this.time,
  });

  final int amount;
  final String note;
  final DateTime time;
}