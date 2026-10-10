import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/date_only.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/dashboard/data/mock_dashboard_data.dart';
import 'package:milbeki_app/features/dashboard/domain/dashboard_models.dart';
import 'package:milbeki_app/features/money_owed/data/mock_debt_data.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_rules.dart';

final _today = DateTime(2026, 10, 10, 15, 30);

List<String> _names(List<Debt> debts) => debts.map((d) => d.personName).toList();

void main() {
  final debts = MockDebtData.sample();

  test('the sample data is sensible', () {
    expect(debts.length, 5);
    for (final debt in debts) {
      // No overpaid debts.
      expect(debt.paidAmount.paisa <= debt.originalAmount.paisa, isTrue);
      for (final payment in debt.payments) {
        // Every payment is in the past and not before the debt began.
        expect(payment.paidAt.isAfter(_today), isFalse);
        expect(
          payment.paidAt.dateOnly.isBefore(debt.startDate.dateOnly),
          isFalse,
        );
      }
    }
  });

  test('statuses match the worked example', () {
    final statuses = {for (final d in debts) d.personName: d.statusOn(_today)};

    expect(statuses, {
      'Fatir': DebtStatus.partiallyPaid,
      'Rahim': DebtStatus.partiallyPaid,
      'Sabbir': DebtStatus.overdue,
      'Mitu': DebtStatus.paid,
      'Karim': DebtStatus.cancelled,
    });
  });

  test('Phase 1 numbers: Fatir is owed 300 and Rahim owes 200', () {
    final fatir = debts.firstWhere((d) => d.personName == 'Fatir');
    final rahim = debts.firstWhere((d) => d.personName == 'Rahim');

    expect(fatir.outstanding, Money.taka(300));
    expect(rahim.outstanding, Money.taka(200));
  });

  test('summary of the sample debts', () {
    final summary = DebtSummary.of(debts, today: _today);

    expect(summary.youOweTotal, Money.taka(300));
    expect(summary.owedToYouTotal, Money.taka(1200));
    expect(summary.youOweOverdue, Money.zero);
    expect(summary.owedToYouOverdue, Money.taka(1000));
    expect(_names(summary.dueSoon), ['Rahim']);
    expect(summary.partiallySettledCount, 2);
  });

  group('filter and sort', () {
    List<Debt> run({
      DebtDirection? direction,
      DebtStatus? status,
      String search = '',
      DebtSort sort = DebtSort.dueDate,
    }) =>
        DebtRules.filter(
          debts,
          today: _today,
          direction: direction,
          status: status,
          search: search,
          sort: sort,
        );

    test('sorted by due date, earliest first', () {
      expect(_names(run()), ['Mitu', 'Sabbir', 'Karim', 'Rahim', 'Fatir']);
    });

    test('sorted by outstanding amount, largest first', () {
      expect(
        _names(run(sort: DebtSort.amount)),
        ['Sabbir', 'Karim', 'Fatir', 'Rahim', 'Mitu'],
      );
    });

    test('filtered by direction', () {
      expect(_names(run(direction: DebtDirection.youOwe)), ['Mitu', 'Fatir']);
      expect(
        _names(run(direction: DebtDirection.owedToYou, sort: DebtSort.amount)),
        ['Sabbir', 'Karim', 'Rahim'],
      );
    });

    test('filtered by status', () {
      expect(_names(run(status: DebtStatus.overdue)), ['Sabbir']);
      expect(_names(run(status: DebtStatus.cancelled)), ['Karim']);
      expect(_names(run(status: DebtStatus.paid)), ['Mitu']);
      expect(
        _names(run(status: DebtStatus.partiallyPaid)),
        ['Rahim', 'Fatir'],
      );
    });

    test('search ignores case, and a blank search matches everything', () {
      expect(_names(run(search: 'RAH')), ['Rahim']);
      expect(run(search: '   ').length, 5);
      expect(run(search: 'zzz'), isEmpty);
    });
  });

  test('the dashboard debt rows come from the debt records', () {
    final dashboardItems = MockDashboardData.sample().dueItems;
    final debtItems = DebtRules.toDueItems(debts);

    expect(debtItems.length, 3); // Fatir, Rahim, Sabbir

    for (final item in debtItems) {
      final found = dashboardItems.any(
        (d) =>
            d.title == item.title &&
            d.amount == item.amount &&
            d.dueDate == item.dueDate &&
            d.kind == item.kind,
      );
      expect(found, isTrue, reason: item.title);
    }

    final debtKinds = dashboardItems.where((i) => i.kind != DueKind.bill);
    expect(debtKinds.length, debtItems.length);
  });
}