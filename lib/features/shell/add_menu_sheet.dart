import 'package:flutter/material.dart';

// Opens the "what do you want to add?" panel from the bottom of the screen.
Future<void> showAddMenu(BuildContext context) {
  // Grab the messenger now, while this context is still valid. The sheet closes
  // before we show the message, and a closed sheet's context cannot be used.
  final messenger = ScaffoldMessenger.of(context);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      void choose(String label) {
        Navigator.of(sheetContext).pop(); // close the sheet
        messenger.showSnackBar(
          SnackBar(content: Text('$label is built in a later step.')),
        );
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min, // only as tall as its content
          children: [
            _AddOption(
              icon: Icons.north_east,
              label: 'Add Expense',
              onTap: () => choose('Add Expense'),
            ),
            _AddOption(
              icon: Icons.south_west,
              label: 'Add Income',
              onTap: () => choose('Add Income'),
            ),
            _AddOption(
              icon: Icons.swap_horiz,
              label: 'Add Money Owed',
              onTap: () => choose('Add Money Owed'),
            ),
            _AddOption(
              icon: Icons.event_repeat,
              label: 'Add Recurring Expense',
              onTap: () => choose('Add Recurring Expense'),
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