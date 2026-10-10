import 'package:flutter/material.dart';
import 'package:milbeki_app/features/shell/add_menu_sheet.dart';
import 'package:milbeki_app/features/shell/placeholder_page.dart';

// The frame around the main app: a body that changes, and the bottom bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // The Add button is the third destination (index 2). It is not a real tab.
  static const int _addIndex = 2;

  int _selectedIndex = 0;

  // One page per destination. Index 2 is an empty box that is never shown.
  // The placeholders are replaced by real screens in the next steps.
  final List<Widget> _pages = const [
    PlaceholderPage(
      icon: Icons.home_outlined,
      message: 'Your dashboard will appear here.',
    ),
    PlaceholderPage(
      icon: Icons.calendar_month_outlined,
      message: 'Your financial calendar will appear here.',
    ),
    SizedBox.shrink(),
    PlaceholderPage(
      icon: Icons.swap_horiz,
      message: 'Money you owe and are owed will appear here.',
    ),
    PlaceholderPage(
      icon: Icons.menu,
      message: 'Analytics, accounts and settings will appear here.',
    ),
  ];

  void _onDestinationSelected(int index) {
    if (index == _addIndex) {
      // Open the sheet but keep the current tab selected.
      showAddMenu(context);
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      // IndexedStack keeps every tab alive and shows only the selected one.
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle, size: 36, color: primary),
            label: 'Add',
          ),
          const NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            label: 'Money Owed',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }
}