import 'package:flutter/material.dart';
import 'package:milbeki_app/features/calendar/application/calendar_store.dart';
import 'package:milbeki_app/features/calendar/data/mock_calendar_data.dart';
import 'package:milbeki_app/features/calendar/presentation/calendar_screen.dart';
import 'package:milbeki_app/features/dashboard/data/mock_dashboard_data.dart';
import 'package:milbeki_app/features/dashboard/domain/dashboard_models.dart';
import 'package:milbeki_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:milbeki_app/features/money_owed/application/debt_store.dart';
import 'package:milbeki_app/features/money_owed/data/mock_debt_data.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_rules.dart';
import 'package:milbeki_app/features/money_owed/presentation/add_debt_flow.dart';
import 'package:milbeki_app/features/money_owed/presentation/money_owed_screen.dart';
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

  // Sample data for now; the server replaces it in a later phase.
  late final DashboardData _baseDashboard = MockDashboardData.sample();

  // The one shared list of debts. Money Owed, Home and the Calendar read it.
  late final DebtStore _debtStore = DebtStore(MockDebtData.sample());

  // Bills and expected income, read by the Calendar.
  late final CalendarStore _calendarStore = CalendarStore(
    bills: MockCalendarData.bills(),
    expectedIncome: MockCalendarData.expectedIncome(),
  );

  // One page per destination. Index 2 is an empty box that is never shown.
  late final List<Widget> _pages = [
    ListenableBuilder(
      listenable: _debtStore,
      builder: (context, _) =>
          DashboardScreen(data: _dashboardFor(_debtStore.debts)),
    ),
    CalendarScreen(
      debtStore: _debtStore,
      calendarStore: _calendarStore,
      now: () => _baseDashboard.now,
    ),
    const SizedBox.shrink(),
    MoneyOwedScreen(store: _debtStore, now: () => _baseDashboard.now),
    const PlaceholderPage(
      icon: Icons.menu,
      message: 'Analytics, accounts and settings will appear here.',
    ),
  ];

  // The sample dashboard, with its debt rows rebuilt from the current debts.
  // Bills stay as they were; every debt row comes from the store.
  DashboardData _dashboardFor(List<Debt> debts) {
    final base = _baseDashboard;
    return DashboardData(
      userName: base.userName,
      now: base.now,
      cycle: base.cycle,
      moneyHeld: base.moneyHeld,
      periodIncome: base.periodIncome,
      periodExpenses: base.periodExpenses,
      monthlyBudget: base.monthlyBudget,
      savingsRemaining: base.savingsRemaining,
      categories: base.categories,
      todayExpenses: base.todayExpenses,
      dueItems: [
        ...base.dueItems.where((item) => item.kind == DueKind.bill),
        ...DebtRules.toDueItems(debts),
      ],
    );
  }

  void _addDebt() {
    openAddDebt(context, store: _debtStore, now: () => _baseDashboard.now);
  }

  void _onDestinationSelected(int index) {
    if (index == _addIndex) {
      // Open the sheet but keep the current tab selected.
      showAddMenu(context, onAddDebt: _addDebt);
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    _debtStore.dispose();
    _calendarStore.dispose();
    super.dispose();
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