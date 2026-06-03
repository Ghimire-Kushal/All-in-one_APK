import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/timetable_entry.dart';
import '../../providers/timetable_provider.dart';

// ─── Categories ───────────────────────────────────────────────────────────────

class _Category {
  final String label;
  final IconData icon;
  final Color color;
  const _Category(this.label, this.icon, this.color);
}

const _kCategories = [
  _Category('Morning', Icons.wb_sunny_rounded, Color(0xFFFFB74D)),
  _Category('Exercise', Icons.fitness_center_rounded, Color(0xFFEF5350)),
  _Category('Meal', Icons.restaurant_rounded, Color(0xFF66BB6A)),
  _Category('Study', Icons.menu_book_rounded, Color(0xFF42A5F5)),
  _Category('Work', Icons.laptop_rounded, Color(0xFF5C6BC0)),
  _Category('Break', Icons.local_cafe_rounded, Color(0xFF8D6E63)),
  _Category('Personal', Icons.self_improvement_rounded, Color(0xFFAB47BC)),
  _Category('Other', Icons.star_rounded, Color(0xFF26A69A)),
];

const _kDayShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _kDayFull = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _kDayFullName = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday'
];

Color _colorFromHex(String hex) =>
    Color(int.parse(hex.padLeft(8, 'F'), radix: 16));

// ─── Main Screen ─────────────────────────────────────────────────────────────

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _openSheet({TimetableEntry? entry}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivitySheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Routine',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Today'), Tab(text: 'All Days')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_TodayTab(onEdit: _openSheet), _AllDaysTab(onEdit: _openSheet)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSheet(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Activity'),
      ),
    );
  }
}

// ─── Today Tab ───────────────────────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  final void Function({TimetableEntry? entry}) onEdit;
  const _TodayTab({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimetableProvider>();
    final entries = provider.todayEntries;
    final next = provider.nextTodayEntry;
    final dayName = _kDayFullName[DateTime.now().weekday - 1];

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.free_breakfast_rounded, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Free $dayName!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500])),
            const SizedBox(height: 6),
            Text('No activities scheduled today.',
                style: TextStyle(fontSize: 13, color: Colors.grey[400])),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (next != null) ...[
          _NextBanner(entry: next),
          const SizedBox(height: 16),
        ],
        _ProgressBar(entries: entries),
        const SizedBox(height: 16),
        ...entries.map((e) => _ActivityTile(entry: e, onEdit: () => onEdit(entry: e))),
      ],
    );
  }
}

// ─── Progress bar showing how much of today's routine is done ────────────────

class _ProgressBar extends StatelessWidget {
  final List<TimetableEntry> entries;
  const _ProgressBar({required this.entries});

  @override
  Widget build(BuildContext context) {
    final nowMin = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
    final done = entries.where((e) {
      final end = (e.endHour != null && e.endMinute != null)
          ? e.endHour! * 60 + e.endMinute!
          : e.startMinutes + 30;
      return nowMin >= end;
    }).length;

    final progress = entries.isEmpty ? 0.0 : done / entries.length;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Today\'s Progress',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: cs.onPrimaryContainer)),
              const Spacer(),
              Text('$done / ${entries.length} done',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: cs.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: cs.primary.withValues(alpha: 0.12),
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Next Activity Banner ─────────────────────────────────────────────────────

class _NextBanner extends StatelessWidget {
  final TimetableEntry entry;
  const _NextBanner({required this.entry});

  String _countdown() {
    final now = TimeOfDay.now();
    final diff = entry.startMinutes - (now.hour * 60 + now.minute);
    if (diff <= 0) return 'Now';
    if (diff < 60) return 'In $diff min';
    final h = diff ~/ 60;
    final m = diff % 60;
    return m == 0 ? 'In ${h}h' : 'In ${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final cat = _kCategories[entry.categoryIndex.clamp(0, 7)];
    final color = _colorFromHex(entry.colorHex);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1F2A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(cat.icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Up next',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(entry.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(entry.startLabel,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500])),
                    if (entry.endLabel != null) ...[
                      Text(' – ${entry.endLabel}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_countdown(),
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── All Days Tab ─────────────────────────────────────────────────────────────

class _AllDaysTab extends StatelessWidget {
  final void Function({TimetableEntry? entry}) onEdit;
  const _AllDaysTab({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimetableProvider>();
    final today = DateTime.now().weekday;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: 7,
      itemBuilder: (_, i) {
        final day = i + 1;
        final entries = provider.forDay(day);
        return _DaySection(
          dayShort: _kDayFull[i],
          dayFull: _kDayFullName[i],
          entries: entries,
          isToday: day == today,
          onEdit: onEdit,
        );
      },
    );
  }
}

class _DaySection extends StatefulWidget {
  final String dayShort, dayFull;
  final List<TimetableEntry> entries;
  final bool isToday;
  final void Function({TimetableEntry? entry}) onEdit;

  const _DaySection({
    required this.dayShort,
    required this.dayFull,
    required this.entries,
    required this.isToday,
    required this.onEdit,
  });

  @override
  State<_DaySection> createState() => _DaySectionState();
}

class _DaySectionState extends State<_DaySection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isToday || widget.entries.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.isToday
                        ? cs.primary
                        : cs.primaryContainer.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(widget.dayShort,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: widget.isToday
                                ? Colors.white
                                : cs.onPrimaryContainer)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(widget.dayFull,
                    style: TextStyle(
                        fontWeight: widget.isToday
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 15,
                        color: widget.isToday ? cs.primary : null)),
                const SizedBox(width: 8),
                if (widget.entries.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${widget.entries.length}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onPrimaryContainer)),
                  ),
                const Spacer(),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          if (widget.entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 8),
              child: Text('No activities',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            )
          else
            ...widget.entries.map((e) => _ActivityTile(
                entry: e, onEdit: () => widget.onEdit(entry: e))),
        ],
        Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── Activity Tile ────────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final TimetableEntry entry;
  final VoidCallback onEdit;

  const _ActivityTile({required this.entry, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final cat = _kCategories[entry.categoryIndex.clamp(0, 7)];
    final color = _colorFromHex(entry.colorHex);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nowMin = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
    final endMin = (entry.endHour != null && entry.endMinute != null)
        ? entry.endHour! * 60 + entry.endMinute!
        : entry.startMinutes + 30;
    final isNow = entry.startMinutes <= nowMin && nowMin < endMin &&
        DateTime.now().weekday == entry.days.firstOrNull;
    final isPast = nowMin >= endMin && DateTime.now().weekday == entry.days.firstOrNull;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete activity?'),
          content: Text('Remove "${entry.title}" from your routine?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
      onDismissed: (_) =>
          context.read<TimetableProvider>().deleteEntry(entry.id),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1F2A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isNow
                ? Border.all(color: color.withValues(alpha: 0.6), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              // Left color bar
              Container(
                width: 5,
                height: 70,
                decoration: BoxDecoration(
                  color: isPast
                      ? color.withValues(alpha: 0.25)
                      : color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPast
                      ? Colors.grey.withValues(alpha: 0.1)
                      : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon,
                    size: 20,
                    color: isPast ? Colors.grey[400] : color),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isPast ? Colors.grey[400] : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isNow) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('NOW',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: color,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 11,
                            color: isPast
                                ? Colors.grey[400]
                                : Colors.grey[500]),
                        const SizedBox(width: 3),
                        Text(
                          entry.endLabel != null
                              ? '${entry.startLabel} – ${entry.endLabel}'
                              : entry.startLabel,
                          style: TextStyle(
                              fontSize: 12,
                              color: isPast
                                  ? Colors.grey[400]
                                  : Colors.grey[600]),
                        ),
                        if (entry.isEveryDay) ...[
                          const SizedBox(width: 8),
                          _chip('Every day', Colors.teal),
                        ] else if (entry.days.length < 7) ...[
                          const SizedBox(width: 8),
                          _chip(
                            entry.days
                                .map((d) => _kDayShort[d - 1])
                                .join(' '),
                            color,
                          ),
                        ],
                        if (entry.notifyEnabled) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.notifications_active_rounded,
                              size: 11, color: color),
                        ],
                      ],
                    ),
                    if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(entry.notes!,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[400]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 18, color: Colors.grey[400]),
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600)),
      );
}

// ─── Add / Edit Activity Sheet ────────────────────────────────────────────────

class _ActivitySheet extends StatefulWidget {
  final TimetableEntry? entry;
  const _ActivitySheet({this.entry});

  @override
  State<_ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends State<_ActivitySheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late int _catIdx;
  late List<int> _days;
  late TimeOfDay _start;
  late TimeOfDay? _end;
  late bool _notifyEnabled;
  late int _notifyMinutes;

  bool get _isEdit => widget.entry != null;

  // Auto-pick color from category
  Color get _color => _kCategories[_catIdx].color;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _catIdx = e?.categoryIndex ?? 7;
    _days = e != null ? List.from(e.days) : [1, 2, 3, 4, 5, 6, 7];
    _start = e != null
        ? TimeOfDay(hour: e.startHour, minute: e.startMinute)
        : const TimeOfDay(hour: 7, minute: 0);
    _end = (e?.endHour != null && e?.endMinute != null)
        ? TimeOfDay(hour: e!.endHour!, minute: e.endMinute!)
        : null;
    _notifyEnabled = e?.notifyEnabled ?? true;
    _notifyMinutes = e?.notifyMinutesBefore ?? 0;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : (_end ?? _start),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        // push end forward if it's before start
        if (_end != null) {
          final startMin = picked.hour * 60 + picked.minute;
          final endMin = _end!.hour * 60 + _end!.minute;
          if (endMin <= startMin) {
            final newEnd = startMin + 60;
            _end = TimeOfDay(
                hour: (newEnd ~/ 60) % 24, minute: newEnd % 60);
          }
        }
      } else {
        _end = picked;
      }
    });
  }

  void _toggleDay(int day) {
    setState(() {
      if (_days.contains(day)) {
        if (_days.length > 1) _days.remove(day);
      } else {
        _days.add(day);
        _days.sort();
      }
    });
  }

  void _toggleEveryDay() {
    setState(() {
      if (_days.length == 7) {
        _days = [DateTime.now().weekday];
      } else {
        _days = [1, 2, 3, 4, 5, 6, 7];
      }
    });
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) return;
    final colorHex = _color
        .toARGB32()
        .toRadixString(16)
        .toUpperCase()
        .padLeft(8, '0');
    final provider = context.read<TimetableProvider>();

    if (_isEdit) {
      provider.updateEntry(widget.entry!.copyWith(
        title: _titleCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        categoryIndex: _catIdx,
        days: _days,
        startHour: _start.hour,
        startMinute: _start.minute,
        endHour: _end?.hour,
        endMinute: _end?.minute,
        colorHex: colorHex,
        notifyEnabled: _notifyEnabled,
        notifyMinutesBefore: _notifyMinutes,
      ));
    } else {
      final entry = provider.buildNew(
        title: _titleCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        categoryIndex: _catIdx,
        days: _days,
        startHour: _start.hour,
        startMinute: _start.minute,
        endHour: _end?.hour,
        endMinute: _end?.minute,
        colorHex: colorHex,
        notifyEnabled: _notifyEnabled,
        notifyMinutesBefore: _notifyMinutes,
      );
      provider.addEntry(entry);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1117) : const Color(0xFFF4F6FB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Text(_isEdit ? 'Edit Activity' : 'New Activity',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),

            // Category picker
            const Text('Category',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
              children: List.generate(_kCategories.length, (i) {
                final cat = _kCategories[i];
                final sel = _catIdx == i;
                return GestureDetector(
                  onTap: () => setState(() => _catIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: sel
                          ? cat.color.withValues(alpha: 0.15)
                          : (isDark
                              ? const Color(0xFF1C1F2A)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: sel
                              ? cat.color
                              : Colors.grey.withValues(alpha: 0.2),
                          width: sel ? 1.5 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat.icon,
                            color: sel ? cat.color : Colors.grey[400],
                            size: 22),
                        const SizedBox(height: 4),
                        Text(cat.label,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: sel ? cat.color : Colors.grey[500])),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),

            // Title
            TextField(
              controller: _titleCtrl,
              autofocus: !_isEdit,
              decoration: InputDecoration(
                labelText: 'Activity name *',
                prefixIcon: Icon(_kCategories[_catIdx].icon,
                    size: 18, color: _color),
              ),
            ),
            const SizedBox(height: 10),

            // Notes
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon:
                    Icon(Icons.notes_rounded, size: 18),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),

            // Days
            Row(
              children: [
                const Text('Repeat on',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleEveryDay,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _days.length == 7
                          ? _color.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _days.length == 7
                              ? _color
                              : Colors.grey[300]!),
                    ),
                    child: Text('Every day',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _days.length == 7
                                ? _color
                                : Colors.grey[600])),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(7, (i) {
                final day = i + 1;
                final sel = _days.contains(day);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleDay(day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(right: i < 6 ? 6 : 0),
                      height: 36,
                      decoration: BoxDecoration(
                        color: sel
                            ? _color.withValues(alpha: 0.15)
                            : (isDark
                                ? const Color(0xFF1C1F2A)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel
                                ? _color
                                : Colors.grey.withValues(alpha: 0.25),
                            width: sel ? 1.5 : 1),
                      ),
                      child: Center(
                        child: Text(_kDayShort[i],
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sel ? _color : Colors.grey[400])),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),

            // Time
            const Text('Time',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _timeBtn('Start', _start, () => _pickTime(true))),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (_end == null) {
                        await _pickTime(false);
                      } else {
                        setState(() => _end = null);
                      }
                    },
                    child: _end != null
                        ? _timeBtn('End', _end!, () => _pickTime(false),
                            clearable: true,
                            onClear: () => setState(() => _end = null))
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1C1F2A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_rounded,
                                    size: 16, color: Colors.grey[400]),
                                const SizedBox(width: 8),
                                Text('Add end time',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500])),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Notification
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _notifyEnabled
                    ? _color.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _notifyEnabled
                      ? _color.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _notifyEnabled
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        color: _notifyEnabled ? _color : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Reminder',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _notifyEnabled
                                    ? null
                                    : Colors.grey[500])),
                      ),
                      Switch.adaptive(
                        value: _notifyEnabled,
                        onChanged: (v) =>
                            setState(() => _notifyEnabled = v),
                        activeThumbColor: _color,
                        activeTrackColor: _color.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                  if (_notifyEnabled) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [0, 5, 10, 15, 30].map((m) {
                        final sel = _notifyMinutes == m;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _notifyMinutes = m),
                            child: Container(
                              margin:
                                  const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6),
                              decoration: BoxDecoration(
                                color: sel
                                    ? _color.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                    color: sel
                                        ? _color
                                        : Colors.grey[300]!),
                              ),
                              child: Center(
                                child: Text(
                                  m == 0 ? 'At time' : '${m}m',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: sel
                                          ? _color
                                          : Colors.grey[500]),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: Icon(_isEdit
                    ? Icons.save_rounded
                    : Icons.add_rounded),
                label: Text(
                    _isEdit ? 'Save Changes' : 'Add Activity'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeBtn(
    String label,
    TimeOfDay time,
    VoidCallback onTap, {
    bool clearable = false,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, size: 16, color: _color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey[500])),
                  Text(_fmtTime(time),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _color)),
                ],
              ),
            ),
            if (clearable && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    size: 14, color: Colors.grey[400]),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
  }
}
