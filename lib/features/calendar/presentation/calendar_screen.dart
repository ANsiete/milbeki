import 'package:flutter/material.dart';
import 'package:milbeki_app/core/utils/date_format.dart';
import 'package:milbeki_app/core/utils/date_only.dart';
import 'package:milbeki_app/core/utils/month_grid.dart';
import 'package:milbeki_app/core/widgets/money_text.dart';
import 'package:milbeki_app/features/calendar/application/calendar_store.dart';
import 'package:milbeki_app/features/calendar/domain/calendar_events.dart';
import 'package:milbeki_app/features/calendar/presentation/calendar_display.dart';
import 'package:milbeki_app/features/money_owed/application/debt_store.dart';
import 'package:milbeki_app/features/money_owed/presentation/debt_detail_screen.dart';

// The Calendar tab. It stores nothing: every event is rebuilt from the real
// records (debts, bills, expected income) each time, so it can never drift
// out of date or show a duplicate.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.debtStore,
    required this.calendarStore,
    required this.now,
  });

  final DebtStore debtStore;
  final CalendarStore calendarStore;

  /// The clock. The sample app passes a fixed date.
  final DateTime Function() now;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Weeks start on Saturday, as in Bangladesh. Change this one line to change it.
  static const int _weekStart = DateTime.saturday;
  static const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late DateTime _month; // the first day of the month being shown
  late DateTime _selected; // the day whose events are listed below the grid
  Set<CalendarEventKind> _kinds = CalendarEventKind.values.toSet();

  @override
  void initState() {
    super.initState();
    final today = widget.now().dateOnly;
    _month = DateTime(today.year, today.month, 1);
    _selected = today;
  }

  // Selecting a day from a neighbouring month also moves the view there.
  void _selectDay(DateTime date) {
    final day = date.dateOnly;
    setState(() {
      _selected = day;
      _month = DateTime(day.year, day.month, 1);
    });
  }

  void _changeMonth(int delta) {
    final today = widget.now().dateOnly;
    final next = MonthGrid.addMonths(_month, delta);
    setState(() {
      _month = next;
      // This month: select today. Any other month: select its 1st.
      _selected =
          (next.year == today.year && next.month == today.month) ? today : next;
    });
  }

  void _goToday() {
    final today = widget.now().dateOnly;
    setState(() {
      _month = DateTime(today.year, today.month, 1);
      _selected = today;
    });
  }

  void _toggleKind(CalendarEventKind kind) {
    final next = {..._kinds};
    if (!next.add(kind)) next.remove(kind);
    setState(() => _kinds = next);
  }

  // Events are sorted by date, so the first overdue one is the oldest.
  void _jumpToOverdue(List<CalendarEvent> events, DateTime today) {
    for (final event in events) {
      if (event.isOverdueOn(today)) {
        _selectDay(event.date);
        return;
      }
    }
  }

  void _openEvent(CalendarEvent event) {
    switch (event.kind) {
      case CalendarEventKind.debtYouOwe:
      case CalendarEventKind.owedToYou:
        _openDebt(event);
      case CalendarEventKind.bill:
      case CalendarEventKind.expectedIncome:
        _showActionSheet(event);
    }
  }

  // A debt event opens the real debt. Recording a payment there updates the
  // shared store, so the calendar, Money Owed and Home all follow.
  void _openDebt(CalendarEvent event) {
    final matches = widget.debtStore.debts.where((d) => d.id == event.sourceId);
    if (matches.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DebtDetailScreen(
          debt: matches.first,
          now: widget.now,
          onChanged: widget.debtStore.replace,
        ),
      ),
    );
  }

  Future<void> _showActionSheet(CalendarEvent event) {
    // Grab the messenger now, while this context is still valid.
    final messenger = ScaffoldMessenger.of(context);
    final isBill = event.kind == CalendarEventKind.bill;
    final overdue = event.isOverdueOn(widget.now());

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                MoneyText(
                  event.amount,
                  colorNegative: false,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  isBill
                      ? 'Due ${AppDates.weekdayDate(event.date)}'
                      : 'Expected ${AppDates.weekdayDate(event.date)}',
                ),
                if (overdue)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      isBill
                          ? 'This bill is overdue.'
                          : 'This was expected earlier and has not been received.',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  isBill
                      ? 'Marking this bill as paid removes it from your '
                          'calendar. Sample only: no transaction is created '
                          'yet, so your account balances and Home do not '
                          'change. In the finished app you will choose the '
                          'account it is paid from.'
                      : 'Marking this as received removes it from your '
                          'calendar. Sample only: no transaction is created '
                          'yet, so your account balances and Home do not '
                          'change. In the finished app you will choose the '
                          'account it arrived in.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    key: const Key('markDoneButton'),
                    onPressed: () {
                      Navigator.of(sheetContext).pop(); // close the sheet
                      _markDone(event, messenger);
                    },
                    child: Text(isBill ? 'Mark as paid' : 'Mark as received'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _markDone(CalendarEvent event, ScaffoldMessengerState messenger) {
    final now = widget.now();
    final String text;

    if (event.kind == CalendarEventKind.bill) {
      widget.calendarStore.markBillPaid(event.sourceId, now);
      text = 'Marked as paid: ${event.title}, ${event.amount.format()}.';
    } else {
      widget.calendarStore.markIncomeReceived(event.sourceId, now);
      text = 'Marked as received: ${event.amount.format()}.';
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('$text (Sample only: no transaction was created.)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      // Rebuilds whenever either store changes.
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.debtStore, widget.calendarStore]),
        builder: (context, _) {
          final today = widget.now();
          final todayDay = today.dateOnly;

          // The calendar stores nothing: events are rebuilt from the records.
          final events = CalendarEvents.ofKinds(
            CalendarEvents.build(
              debts: widget.debtStore.debts,
              bills: widget.calendarStore.bills,
              expectedIncome: widget.calendarStore.expectedIncome,
            ),
            _kinds,
          );
          final byDay = CalendarEvents.byDay(events);
          final monthTotals = EventTotals.of(
            CalendarEvents.inMonth(events, _month.year, _month.month),
            today: today,
          );
          final overdueCount =
              EventTotals.of(events, today: today).overdueCount;
          final grid = MonthGrid.of(
            _month.year,
            _month.month,
            weekStartsOn: _weekStart,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Calendar',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    key: const Key('todayButton'),
                    onPressed: _goToday,
                    child: const Text('Today'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    key: const Key('prevMonthButton'),
                    tooltip: 'Previous month',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Expanded(
                    child: Text(
                      AppDates.monthYear(_month),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    key: const Key('nextMonthButton'),
                    tooltip: 'Next month',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (overdueCount > 0) ...[
                _OverdueBanner(
                  count: overdueCount,
                  onShow: () => _jumpToOverdue(events, today),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'To pay this month',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 2),
                                MoneyText(
                                  monthTotals.moneyOut,
                                  key: const Key('monthOut'),
                                  colorNegative: false,
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Coming in',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 2),
                                MoneyText(
                                  monthTotals.moneyIn,
                                  key: const Key('monthIn'),
                                  colorNegative: false,
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Money coming in is not in your accounts until you '
                        'receive it.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final kind in CalendarEventKind.values)
                    FilterChip(
                      key: Key('kind-${kind.name}'),
                      avatar: Icon(kindIcon(kind), size: 18),
                      label: Text(kindFilterLabel(kind)),
                      selected: _kinds.contains(kind),
                      onSelected: (_) => _toggleKind(kind),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const _Legend(),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Center(
                        child: Text(
                          _weekdayNames[(_weekStart - 1 + i) % 7],
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              for (final week in grid.weeks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      for (final day in week)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _DayCell(
                              date: day,
                              summary: byDay[day],
                              inMonth: grid.isInMonth(day),
                              isToday: day == todayDay,
                              isSelected: day == _selected,
                              onTap: () => _selectDay(day),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              _DayPanel(
                date: _selected,
                summary: byDay[_selected],
                today: today,
                onOpen: _openEvent,
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

String _isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

// What a screen reader says for a day cell, so colour is never the only clue.
String _dayLabel(DateTime date, DaySummary? summary) {
  final parts = <String>[AppDates.weekdayDate(date)];
  final payments = summary?.obligationCount ?? 0;
  if (payments > 0) {
    parts.add('$payments ${payments == 1 ? 'payment' : 'payments'} due');
  }
  if (summary?.events.any((e) => e.isMoneyIn) ?? false) {
    parts.add('money coming in');
  }
  return parts.join(', ');
}

class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner({required this.count, required this.onShow});

  final int count;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$count overdue ${count == 1 ? 'item' : 'items'}',
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              key: const Key('showOverdueButton'),
              onPressed: onShow,
              child: const Text('Show'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall;

    Widget swatch(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: style),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        swatch(busyColor(BusyLevel.light), '1 payment'),
        swatch(busyColor(BusyLevel.medium), '2 payments'),
        swatch(busyColor(BusyLevel.heavy), '3+ payments'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Dot(color: Color(0xFF2E7D32)),
            const SizedBox(width: 4),
            Text('Money coming in', style: style),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.summary,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final DaySummary? summary;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = summary;

    final obligations = s?.obligationCount ?? 0;
    final hasMoneyIn = s?.events.any((e) => e.isMoneyIn) ?? false;
    final level = s?.busyLevel ?? BusyLevel.none;
    final shownDots = obligations > 3 ? 3 : obligations;

    final Color borderColor;
    if (isSelected) {
      borderColor = scheme.primary;
    } else if (isToday) {
      borderColor = scheme.outline;
    } else {
      borderColor = Colors.transparent;
    }

    final numberStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
      color: inMonth ? null : scheme.onSurface.withValues(alpha: 0.4),
    );

    return Semantics(
      label: _dayLabel(date, s),
      button: true,
      selected: isSelected,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          key: Key('day-${_isoDay(date)}'),
          height: 52,
          decoration: BoxDecoration(
            color: busyColor(level),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${date.day}', style: numberStyle),
              const SizedBox(height: 4),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < shownDots; i++)
                      _Dot(color: scheme.onSurface),
                    if (hasMoneyIn) const _Dot(color: Color(0xFF2E7D32)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPanel extends StatelessWidget {
  const _DayPanel({
    required this.date,
    required this.summary,
    required this.today,
    required this.onOpen,
  });

  final DateTime date;
  final DaySummary? summary;
  final DateTime today;
  final void Function(CalendarEvent event) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = summary;
    final events = s?.events ?? const <CalendarEvent>[];

    final parts = <String>[];
    if (s != null && s.moneyOut.paisa > 0) {
      parts.add('To pay ${s.moneyOut.format()}');
    }
    if (s != null && s.moneyIn.paisa > 0) {
      parts.add('Coming in ${s.moneyIn.format()}');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppDates.weekdayDate(date),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (parts.isNotEmpty)
              Text(parts.join(' · '), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            if (events.isEmpty)
              const Text('Nothing on this day.')
            else
              for (final event in events)
                _EventTile(
                  key: Key('event-${event.id}'),
                  event: event,
                  today: today,
                  onTap: () => onOpen(event),
                ),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    super.key,
    required this.event,
    required this.today,
    required this.onTap,
  });

  final CalendarEvent event;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = event.isOverdueOn(today);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        child: Icon(kindIcon(event.kind), size: 18),
      ),
      title: Text(event.title),
      subtitle: Text(
        eventSubtitle(event, today),
        style: TextStyle(color: overdue ? theme.colorScheme.error : null),
      ),
      trailing: Text(
        // A plus sign marks money coming TO you. It is not in your pocket yet.
        event.isMoneyIn ? '+${event.amount.format()}' : event.amount.format(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: event.isMoneyIn ? theme.colorScheme.primary : null,
        ),
      ),
      onTap: onTap,
    );
  }
}