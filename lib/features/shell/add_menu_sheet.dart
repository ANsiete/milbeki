import 'package:flutter/material.dart';
import 'package:milbeki_app/features/transactions/presentation/add_expense_flow.dart';

// Opens the "what do you want to add?" panel from the bottom of the screen.
// The menu does not know about debts. The shell passes in what to do when
// "Add Money Owed" is chosen.
Future<void> showAddMenu(
  BuildContext context, {
  required VoidCallback onAddDebt,
}) {
  // Grab the messenger now, while this context is still valid. The sheet closes
  // before we show the message, and a closed sheet's context cannot be used.
  final messenger = ScaffoldMessenger.of(context);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      void comingLater(String label) {
        Navigator.of(sheetContext).pop(); // close the sheet
        messenger.showSnackBar(
          SnackBar(content: Text('$label is built in a later step.')),
        );
      }

      void chooseExpense() {
        Navigator.of(sheetContext).pop(); // close the sheet
        openAddExpense(context); // then open the form
      }

      void chooseDebt() {
        Navigator.of(sheetContext).pop(); // close the sheet
        onAddDebt(); // then let the shell open the form
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min, // only as tall as its content
          children: [
            _AddOption(
              icon: Icons.north_east,
              label: 'Add Expense',
              onTap: chooseExpense,
            ),
            _AddOption(
              icon: Icons.south_west,
              label: 'Add Income',
              onTap: () => comingLater('Add Income'),
            ),
            _AddOption(
              icon: Icons.swap_horiz,
              label: 'Add Money Owed',
              onTap: chooseDebt,
            ),
            _AddOption(
              icon: Icons.event_repeat,
              label: 'Add Recurring Expense',
              onTap: () => comingLater('Add Recurring Expense'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        child: Icon(icon, color: colors.onPrimaryContainer),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}