import 'package:flutter_test/flutter_test.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/calendar/application/calendar_store.dart';
import 'package:milbeki_app/features/calendar/domain/calendar_sources.dart';

BillInstance _bill(String id) => BillInstance(
      id: id,
      title: 'Bill $id',
      amount: Money.taka(100),
      dueDate: DateTime(2026, 10, 12),
    );

ExpectedIncome _income(String id) => ExpectedIncome(
      id: id,
      sourceName: 'Tutoring',
      amount: Money.taka(500),
      expectedOn: DateTime(2026, 10, 25),
    );

void main() {
  group('bills', () {
    test('the store keeps a private copy and hands out read-only lists', () {
      final source = [_bill('a')];
      final store = CalendarStore(bills: source, expectedIncome: []);

      source.add(_bill('b')); // changing the original list...
      expect(store.bills.length, 1); // ...does not touch the store
      expect(() => store.bills.add(_bill('c')), throwsUnsupportedError);
    });

    test('marking a bill paid keeps the order, records the time, and notifies once', () {
      final store = CalendarStore(
        bills: [_bill('a'), _bill('b')],
        expectedIncome: [],
      );
      var calls = 0;
      store.addListener(() => calls++);

      store.markBillPaid('a', DateTime(2026, 10, 11, 9, 0));

      expect(store.bills.map((b) => b.id), ['a', 'b']);
      expect(store.bills.first.isOpen, isFalse);
      expect(store.bills.first.paidAt, DateTime(2026, 10, 11, 9, 0));
      expect(store.bills.last.isOpen, isTrue);
      expect(calls, 1);
    });

    test('marking an already paid bill again changes nothing and does not notify', () {
      final store = CalendarStore(bills: [_bill('a')], expectedIncome: []);
      store.markBillPaid('a', DateTime(2026, 10, 11, 9, 0));

      var calls = 0;
      store.addListener(() => calls++);
      store.markBillPaid('a', DateTime(2026, 10, 14, 18, 0));

      expect(store.bills.single.paidAt, DateTime(2026, 10, 11, 9, 0));
      expect(calls, 0);
    });

    test('an unknown bill id does nothing', () {
      final store = CalendarStore(bills: [_bill('a')], expectedIncome: []);
      var calls = 0;
      store.addListener(() => calls++);

      store.markBillPaid('zzz', DateTime(2026, 10, 11));

      expect(store.bills.single.isOpen, isTrue);
      expect(calls, 0);
    });
  });

  group('expected income', () {
    test('marking income received records the time and notifies once', () {
      final store = CalendarStore(
        bills: [],
        expectedIncome: [_income('x'), _income('y')],
      );
      var calls = 0;
      store.addListener(() => calls++);

      store.markIncomeReceived('x', DateTime(2026, 10, 25, 11, 0));

      expect(store.expectedIncome.map((i) => i.id), ['x', 'y']);
      expect(store.expectedIncome.first.isOpen, isFalse);
      expect(
        store.expectedIncome.first.receivedAt,
        DateTime(2026, 10, 25, 11, 0),
      );
      expect(store.expectedIncome.last.isOpen, isTrue);
      expect(calls, 1);
    });

    test('marking received twice keeps the first time and does not notify again', () {
      final store = CalendarStore(bills: [], expectedIncome: [_income('x')]);
      store.markIncomeReceived('x', DateTime(2026, 10, 25, 11, 0));

      var calls = 0;
      store.addListener(() => calls++);
      store.markIncomeReceived('x', DateTime(2026, 10, 26));

      expect(
        store.expectedIncome.single.receivedAt,
        DateTime(2026, 10, 25, 11, 0),
      );
      expect(calls, 0);
    });

    test('an unknown income id does nothing', () {
      final store = CalendarStore(bills: [], expectedIncome: [_income('x')]);
      var calls = 0;
      store.addListener(() => calls++);

      store.markIncomeReceived('zzz', DateTime(2026, 10, 25));

      expect(store.expectedIncome.single.isOpen, isTrue);
      expect(calls, 0);
    });
  });
}