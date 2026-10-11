import 'package:flutter/foundation.dart';
import 'package:milbeki_app/features/calendar/domain/calendar_sources.dart';

// The shared list of bills and expected income. The calendar reads from it.
// Debts are NOT here: they live in the DebtStore, so Money Owed, Home and the
// calendar all see the same debts.
//
// In Phase 6 this becomes a Riverpod provider. Marking a bill paid will also
// create a real transaction then (Phase 9).
class CalendarStore extends ChangeNotifier {
  CalendarStore({
    required List<BillInstance> bills,
    required List<ExpectedIncome> expectedIncome,
  })  : _bills = List.of(bills), // private copies
        _income = List.of(expectedIncome);

  List<BillInstance> _bills;
  List<ExpectedIncome> _income;

  /// Read-only snapshots.
  List<BillInstance> get bills => List.unmodifiable(_bills);
  List<ExpectedIncome> get expectedIncome => List.unmodifiable(_income);

  /// Marks one bill paid. An unknown id, or a bill that is already paid or
  /// skipped, changes nothing and does not notify.
  void markBillPaid(String id, DateTime at) {
    final index = _bills.indexWhere((b) => b.id == id);
    if (index < 0) return;
    final bill = _bills[index];
    if (!bill.isOpen) return;

    _bills = [
      for (var i = 0; i < _bills.length; i++)
        i == index ? bill.markPaid(at) : _bills[i],
    ];
    notifyListeners();
  }

  /// Marks one expected income as received, with the same rules.
  void markIncomeReceived(String id, DateTime at) {
    final index = _income.indexWhere((i) => i.id == id);
    if (index < 0) return;
    final income = _income[index];
    if (!income.isOpen) return;

    _income = [
      for (var i = 0; i < _income.length; i++)
        i == index ? income.markReceived(at) : _income[i],
    ];
    notifyListeners();
  }
}