import 'package:flutter/material.dart';
import 'package:milbeki_app/features/calendar/domain/calendar_events.dart';

// Small display helpers for the calendar.

String kindFilterLabel(CalendarEventKind kind) {
  return switch (kind) {
    CalendarEventKind.bill => 'Bills',
    CalendarEventKind.debtYouOwe => 'Debts you owe',
    CalendarEventKind.owedToYou => 'Owed to you',
    CalendarEventKind.expectedIncome => 'Expected income',
  };
}

IconData kindIcon(CalendarEventKind kind) {
  return switch (kind) {
    CalendarEventKind.bill => Icons.receipt_long,
    CalendarEventKind.debtYouOwe => Icons.call_made,
    CalendarEventKind.owedToYou => Icons.call_received,
    CalendarEventKind.expectedIncome => Icons.savings_outlined,
  };
}

/// The small grey line under an event's title. The words carry the meaning,
/// so nothing depends on colour alone.
String eventSubtitle(CalendarEvent event, DateTime today) {
  final overdue = event.isOverdueOn(today);
  return switch (event.kind) {
    CalendarEventKind.bill => overdue ? 'Bill · Overdue' : 'Bill · Due',
    CalendarEventKind.debtYouOwe =>
      overdue ? 'You owe · Overdue' : 'You owe · Due',
    CalendarEventKind.owedToYou => overdue
        ? 'Owed to you · Overdue, not received yet'
        : 'Owed to you · Expected, not received yet',
    CalendarEventKind.expectedIncome => overdue
        ? 'Income · Was expected, not received yet'
        : 'Income · Expected, not received yet',
  };
}

/// Background of a day cell. The legend and the day panel say the same thing
/// in words.
Color busyColor(BusyLevel level) {
  return switch (level) {
    BusyLevel.none => Colors.transparent,
    BusyLevel.light => Colors.amber.shade100,
    BusyLevel.medium => Colors.orange.shade200,
    BusyLevel.heavy => Colors.red.shade200,
  };
}