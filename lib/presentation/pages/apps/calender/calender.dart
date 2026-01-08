import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:table_calendar/table_calendar.dart';

/* ============================================================
   MODEL
============================================================ */

@immutable
class CalendarEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final Color color;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.color,
  });
}

DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

/* ============================================================
   PROVIDERS
============================================================ */

final focusedDayProvider = StateProvider<DateTime>((_) => DateTime.now());
final selectedDayProvider = StateProvider<DateTime>((_) => DateTime.now());

final eventsProvider =
    StateNotifierProvider<EventsController, Map<DateTime, List<CalendarEvent>>>(
      (_) => EventsController(),
    );

class EventsController
    extends StateNotifier<Map<DateTime, List<CalendarEvent>>> {
  EventsController() : super({});

  void add(CalendarEvent event) {
    final key = _dayKey(event.start);
    state = {
      ...state,
      key: [...(state[key] ?? []), event],
    };
  }

  List<CalendarEvent> eventsFor(DateTime day) {
    return state[_dayKey(day)] ?? [];
  }
}

/* ============================================================
   MAIN SCREEN
============================================================ */

class MacOSCalendarScreen extends ConsumerWidget {
  const MacOSCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      child: Column(
        children: const [
          _Toolbar(),
          Expanded(child: _Body()),
        ],
      ),
    );
  }
}

/* ============================================================
   TOOLBAR (macOS-style)
============================================================ */

class _Toolbar extends ConsumerWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = ref.watch(focusedDayProvider);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.chevron_left, size: 18),
            onPressed: () => ref.read(focusedDayProvider.notifier).state =
                DateTime(focused.year, focused.month - 1),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.chevron_right, size: 18),
            onPressed: () => ref.read(focusedDayProvider.notifier).state =
                DateTime(focused.year, focused.month + 1),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const Text('Today'),
            onPressed: () {
              final now = DateTime.now();
              ref.read(selectedDayProvider.notifier).state = now;
              ref.read(focusedDayProvider.notifier).state = now;
            },
          ),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.add),
            onPressed: () => _showAddEvent(context, ref),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   BODY (RESPONSIVE)
============================================================ */

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final compact = constraints.maxWidth < 1100;

        return Row(
          children: [
            if (!compact) const _MiniCalendar(),
            Expanded(child: _MonthView(compact)),
            if (!compact) const _Agenda(),
          ],
        );
      },
    );
  }
}

/* ============================================================
   MINI CALENDAR (LEFT)
============================================================ */

class _MiniCalendar extends ConsumerWidget {
  const _MiniCalendar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        border: Border(right: BorderSide(color: CupertinoColors.separator)),
      ),
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        focusedDay: ref.watch(focusedDayProvider),
        selectedDayPredicate: (d) =>
            isSameDay(d, ref.watch(selectedDayProvider)),
        onDaySelected: (s, f) {
          ref.read(selectedDayProvider.notifier).state = s;
          ref.read(focusedDayProvider.notifier).state = f;
        },
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Color(0x44FF3B30),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Color(0xFF007AFF),
            shape: BoxShape.circle,
          ),
          defaultTextStyle: TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

/* ============================================================
   MONTH GRID (CENTER)
============================================================ */

class _MonthView extends ConsumerWidget {
  final bool compact;
  const _MonthView(this.compact);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);

    return Container(
      color: CupertinoColors.white,
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        rowHeight: compact ? 50 : 80,
        focusedDay: ref.watch(focusedDayProvider),
        selectedDayPredicate: (d) =>
            isSameDay(d, ref.watch(selectedDayProvider)),
        headerVisible: false,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        eventLoader: (d) => events[_dayKey(d)] ?? [],
        onDaySelected: (s, f) {
          ref.read(selectedDayProvider.notifier).state = s;
          ref.read(focusedDayProvider.notifier).state = f;
        },
        calendarStyle: const CalendarStyle(
          defaultTextStyle: TextStyle(fontSize: 15),
          weekendTextStyle: TextStyle(fontSize: 15),
          todayTextStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF3B30),
          ),
          selectedTextStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF007AFF),
          ),
          todayDecoration: BoxDecoration(
            color: Color(0x22FF3B30),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Color(0x22007AFF),
            shape: BoxShape.circle,
          ),
        ),

        calendarBuilders: CalendarBuilders(
          defaultBuilder: (_, day, __) =>
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _DayCell(day: day, isCompact: compact),
              ),
        ),
      ),
    );
  }
}

/* ============================================================
   DAY CELL (macOS density)
============================================================ */

class _DayCell extends ConsumerWidget {
  final DateTime day;
  final bool isCompact;
  const _DayCell({required this.day, required this.isCompact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider.notifier).eventsFor(day);

    return Container(
      padding: const EdgeInsets.all(6),
      width: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: CupertinoColors.separator, width: .5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 12 : 24,
            ),
          ),
          ...events
              .take(2)
              .map(
                (e) => Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: e.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  // child: Text(
                  //   e.title,
                  //   maxLines: 1,
                  //   overflow: TextOverflow.ellipsis,
                  //   style: const TextStyle(fontSize: 11),
                  // ),
                ),
              ),
        ],
      ),
    );
  }
}

/* ============================================================
   AGENDA (RIGHT)
============================================================ */

class _Agenda extends ConsumerWidget {
  const _Agenda();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref
        .watch(eventsProvider.notifier)
        .eventsFor(ref.watch(selectedDayProvider));

    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        border: Border(left: BorderSide(color: CupertinoColors.separator)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: events.isEmpty
            ? const [Center(child: Text('No Events'))]
            : events
                  .map(
                    (e) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: e.color.withOpacity(.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(e.title),
                    ),
                  )
                  .toList(),
      ),
    );
  }
}

/* ============================================================
   ADD EVENT (Cupertino dialog)
============================================================ */

void _showAddEvent(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();
  final day = ref.read(selectedDayProvider);

  showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: const Text('New Event'),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(
          controller: controller,
          placeholder: 'Event title',
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('Add'),
          onPressed: () {
            ref
                .read(eventsProvider.notifier)
                .add(
                  CalendarEvent(
                    id: DateTime.now().toString(),
                    title: controller.text,
                    start: day,
                    end: day.add(const Duration(hours: 1)),
                    color: const Color(0xFF007AFF),
                  ),
                );
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}
