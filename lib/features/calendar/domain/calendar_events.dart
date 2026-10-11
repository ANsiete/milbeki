import 'package:milbeki_app/core/utils/date_only.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/calendar/domain/calendar_sources.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';

// The order here is also the sort order for events on the same day.
enum CalendarEventKind { bill, debtYouOwe, owedToYou, expectedIncome }

// One line on the calendar. It is a VIEW of a real record, never a record of
// its own. sourceId says which bill, debt or income it came from.
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.kind,
    required this.title,
    required this.amount,
    required this.date,
    required this.sourceId,
  });

  final String id;
  final CalendarEventKind kind;
  final String title;
  final Money amount;

  /// The day it falls on (midnight, no time of day).
  final DateTime date;

  final String sourceId;

  /// Money you must pay out: a bill, or a debt you owe.
  bool get isObligation =>
      kind == CalendarEventKind.bill || kind == CalendarEventKind.debtYouOwe;

  /// Money coming to you: a debt owed to you, or expected income.
  bool get isMoneyIn => !isObligation;

  /// Before today. Due today is not overdue.
  bool isOverdueOn(DateTime today) => date.dateOnly.isBefore(today.dateOnly);
}

enum BusyLevel { none, light, medium, heavy }

// Everything that falls on one day.
class DaySummary {
  const DaySummary({required this.date, required this.events});

  final DateTime date;
  final List<CalendarEvent> events;

  int get obligationCount => events.where((e) => e.isObligation).length;

  Money get moneyOut => events
      .where((e) => e.isObligation)
      .fold<Money>(Money.zero, (sum, e) => sum + e.amount);

  Money get moneyIn => events
      .where((e) => e.isMoneyIn)
      .fold<Money>(Money.zero, (sum, e) => sum + e.amount);

  /// How heavy the day is, counting only what you must pay.
  BusyLevel get busyLevel {
    final count = obligationCount;
    if (count == 0) return BusyLevel.none;
    if (count == 1) return BusyLevel.light;
    if (count == 2) return BusyLevel.medium;
    return BusyLevel.heavy;
  }
}

// Totals for a list of events. Money out and money in are never netted:
// money coming to you is not in your pocket yet.
class EventTotals {
  const EventTotals({
    required this.moneyOut,
    required this.moneyIn,
    required this.overdueCount,
  });

  final Money moneyOut;
  final Money moneyIn;
  final int overdueCount;

  factory EventTotals.of(
    List<CalendarEvent> events, {
    required DateTime today,
  }) {
    var out = Money.zero;
    var coming = Money.zero;
    var overdue = 0;

    for (final event in events) {
      if (event.isObligation) {
        out += event.amount;
      } else {
        coming += event.amount;
      }
      if (event.isOverdueOn(today)) overdue++;
    }

    return EventTotals(moneyOut: out, moneyIn: coming, overdueCount: overdue);
  }
}

class CalendarEvents {
  /// Builds the events from the real records. It stores nothing, so calling it
  /// again gives the same result and can never create duplicates.
  static List<CalendarEvent> build({
    required List<Debt> debts,
    required List<BillInstance> bills,
    required List<ExpectedIncome> expectedIncome,
  }) {
    final events = <CalendarEvent>[];

    for (final bill in bills) {
      // Paid and skipped bills are finished, so they are not shown.
      if (!bill.isOpen) continue;
      events.add(
        CalendarEvent(
          id: 'bill:${bill.id}',
          kind: CalendarEventKind.bill,
          title: bill.title,
          amount: bill.amount,
          date: bill.dueDate.dateOnly,
          sourceId: bill.id,
        ),
      );
    }

    for (final debt in debts) {
      // Paid and cancelled debts are finished, so they are not shown.
      if (!debt.isActive) continue;
      final youOwe = debt.direction == DebtDirection.youOwe;
      events.add(
        CalendarEvent(
          id: 'debt:${debt.id}',
          kind: youOwe
              ? CalendarEventKind.debtYouOwe
              : CalendarEventKind.owedToYou,
          title: youOwe
              ? 'Repay ${debt.personName}'
              : '${debt.personName} will pay you',
          amount: debt.outstanding, // what is LEFT, not the original amount
          date: debt.dueDate.dateOnly,
          sourceId: debt.id,
        ),
      );
    }

    for (final income in expectedIncome) {
      if (!income.isOpen) continue;
      events.add(
        CalendarEvent(
          id: 'income:${income.id}',
          kind: CalendarEventKind.expectedIncome,
          title: '${income.sourceName} expected',
          amount: income.amount,
          date: income.expectedOn.dateOnly,
          sourceId: income.id,
        ),
      );
    }

    events.sort(_compare);
    return events;
  }

  /// Keeps only the chosen kinds. An empty set keeps nothing.
  static List<CalendarEvent> ofKinds(
    List<CalendarEvent> events,
    Set<CalendarEventKind> kinds,
  ) {
    return [
      for (final event in events)
        if (kinds.contains(event.kind)) event,
    ];
  }

  static List<CalendarEvent> inMonth(
    List<CalendarEvent> events,
    int year,
    int month,
  ) {
    return [
      for (final event in events)
        if (event.date.year == year && event.date.month == month) event,
    ];
  }

  /// Groups events by day. Days with no events are absent from the map.
  /// Events keep the order they came in, so pass the output of build().
  static Map<DateTime, DaySummary> byDay(List<CalendarEvent> events) {
    final grouped = <DateTime, List<CalendarEvent>>{};
    for (final event in events) {
      grouped.putIfAbsent(event.date.dateOnly, () => []).add(event);
    }
    return {
      for (final entry in grouped.entries)
        entry.key: DaySummary(
          date: entry.key,
          events: List.unmodifiable(entry.value),
        ),
    };
  }

  // Date first, then kind, then title, then id, so the order never changes
  // between runs.
  static int _compare(CalendarEvent a, CalendarEvent b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    final byKind = a.kind.index.compareTo(b.kind.index);
    if (byKind != 0) return byKind;
    final byTitle = a.title.compareTo(b.title);
    if (byTitle != 0) return byTitle;
    return a.id.compareTo(b.id);
  }
}