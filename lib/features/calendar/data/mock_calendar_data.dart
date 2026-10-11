import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/calendar/domain/calendar_sources.dart';

// Fixed sample bills and expected income. "Today" in the sample app is
// 10 Oct 2026. The server provides real records in a later phase.
class MockCalendarData {
  // The three open bills match the ones on the dashboard (a test checks this).
  // The electricity bill is already paid, so it never shows on the calendar.
  static List<BillInstance> bills() {
    return [
      BillInstance(
        id: 'bill-rent-oct',
        title: 'House rent',
        amount: Money.taka(5000),
        dueDate: DateTime(2026, 10, 15),
      ),
      BillInstance(
        id: 'bill-internet-oct',
        title: 'Internet',
        amount: Money.taka(1000),
        dueDate: DateTime(2026, 10, 20),
      ),
      BillInstance(
        id: 'bill-mobile-nov',
        title: 'Mobile bill',
        amount: Money.taka(400),
        dueDate: DateTime(2026, 11, 3),
      ),
      BillInstance(
        id: 'bill-electricity-sep',
        title: 'Electricity',
        amount: Money.taka(650),
        dueDate: DateTime(2026, 9, 28),
        paidAt: DateTime(2026, 9, 27, 18, 0),
      ),
    ];
  }

  // October's allowance has already arrived (it is the ৳10,000 income on the
  // dashboard), so only the other two appear on the calendar.
  static List<ExpectedIncome> expectedIncome() {
    return [
      ExpectedIncome(
        id: 'inc-tutoring-oct',
        sourceName: 'Tutoring',
        amount: Money.taka(4000),
        expectedOn: DateTime(2026, 10, 25),
      ),
      ExpectedIncome(
        id: 'inc-allowance-nov',
        sourceName: 'Family allowance',
        amount: Money.taka(10000),
        expectedOn: DateTime(2026, 11, 1),
      ),
      ExpectedIncome(
        id: 'inc-allowance-oct',
        sourceName: 'Family allowance',
        amount: Money.taka(10000),
        expectedOn: DateTime(2026, 10, 1),
        receivedAt: DateTime(2026, 10, 1, 9, 0),
      ),
    ];
  }
}