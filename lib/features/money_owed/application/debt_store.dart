import 'package:flutter/foundation.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';

// The one shared list of debts. Both the Money Owed screen and the Home
// dashboard read from it, so they can never disagree.
//
// ChangeNotifier is built into Flutter: call notifyListeners() after a change
// and every ListenableBuilder watching this store rebuilds. In Phase 6 this
// becomes a Riverpod provider; the screens only use add() and replace().
class DebtStore extends ChangeNotifier {
  DebtStore(List<Debt> initial) : _debts = List.of(initial); // a private copy

  List<Debt> _debts;

  /// A read-only snapshot. To change debts, use add() or replace().
  List<Debt> get debts => List.unmodifiable(_debts);

  /// Adds a debt. One whose id already exists is ignored (a retry).
  void add(Debt debt) {
    if (_debts.any((d) => d.id == debt.id)) return;
    _debts = [..._debts, debt];
    notifyListeners();
  }

  /// Swaps in an updated debt, matched by id, keeping the list order.
  void replace(Debt updated) {
    if (!_debts.any((d) => d.id == updated.id)) return;
    _debts = [for (final d in _debts) d.id == updated.id ? updated : d];
    notifyListeners();
  }
}