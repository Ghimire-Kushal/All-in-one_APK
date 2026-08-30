import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../providers/todo_provider.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'To-Do',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (provider.completed.isNotEmpty)
            TextButton(
              onPressed: () => provider.clearCompleted(),
              child: const Text('Clear done', style: TextStyle(fontSize: 12)),
            ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: 'Pending (${provider.pending.length})'),
            Tab(text: 'Done (${provider.completed.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _taskList(context, provider.pending, false),
          _taskList(context, provider.completed, true),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _taskList(BuildContext context, List<Task> tasks, bool isDone) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDone ? Icons.task_alt_rounded : Icons.checklist_rounded,
              size: 60,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              isDone ? 'No completed tasks' : 'No pending tasks',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: tasks.length,
      itemBuilder: (context, i) => _taskTile(context, tasks[i]),
    );
  }

  Widget _taskTile(BuildContext context, Task task) {
    final priorityColors = [Colors.grey, Colors.orange, Colors.red];
    final priorityLabels = ['Low', 'Medium', 'High'];
    final pColor = priorityColors[task.priority.clamp(0, 2)];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasReminder =
        task.reminderTime != null && task.reminderTime!.isAfter(DateTime.now());
    final reminderPast =
        task.reminderTime != null &&
        task.reminderTime!.isBefore(DateTime.now());

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => context.read<TodoProvider>().deleteTask(task.id),
      child: GestureDetector(
        onLongPress: () => _showTaskSheet(context, task: task),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1F2A) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            leading: GestureDetector(
              onTap: () => context.read<TodoProvider>().toggleComplete(task.id),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: task.isCompleted ? Colors.green : Colors.grey[400]!,
                    width: 2,
                  ),
                  color: task.isCompleted ? Colors.green : Colors.transparent,
                ),
                child: task.isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: task.isCompleted ? Colors.grey : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    // Priority badge
                    _badge(
                      label: priorityLabels[task.priority.clamp(0, 2)],
                      color: pColor,
                    ),
                    // Due date
                    if (task.dueDate != null)
                      _badge(
                        icon: Icons.calendar_today_rounded,
                        label: DateFormat('MMM d').format(task.dueDate!),
                        color: Colors.blueGrey,
                      ),
                    // Reminder
                    if (task.reminderTime != null && !task.isCompleted)
                      _badge(
                        icon: hasReminder
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        label: hasReminder
                            ? DateFormat(
                                'MMM d, h:mm a',
                              ).format(task.reminderTime!)
                            : 'Passed',
                        color: hasReminder
                            ? Colors.deepPurple
                            : (reminderPast ? Colors.grey : Colors.deepPurple),
                      ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: Colors.grey[400],
              onPressed: () => _showTaskSheet(context, task: task),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge({IconData? icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Add / Edit Task Bottom Sheet ───────────────────────────────────────────

  void _showTaskSheet(BuildContext context, {Task? task}) {
    final isEdit = task != null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _TaskSheet(task: task, isEdit: isEdit),
    );
  }
}

// ─── Task Sheet (add / edit) ──────────────────────────────────────────────────

class _TaskSheet extends StatefulWidget {
  final Task? task;
  final bool isEdit;

  const _TaskSheet({this.task, required this.isEdit});

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late int _priority;
  late DateTime? _dueDate;
  late DateTime? _reminderTime;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task?.title ?? '');
    _descCtrl = TextEditingController(text: widget.task?.description ?? '');
    _priority = widget.task?.priority ?? 1;
    _dueDate = widget.task?.dueDate;
    _reminderTime = widget.task?.reminderTime;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReminder() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReminderPicker(
        current: _reminderTime,
        onSelected: (dt) => setState(() => _reminderTime = dt),
      ),
    );
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) return;
    final provider = context.read<TodoProvider>();
    if (widget.isEdit && widget.task != null) {
      final updated = Task(
        id: widget.task!.id,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        reminderTime: _reminderTime,
        createdAt: widget.task!.createdAt,
        isCompleted: widget.task!.isCompleted,
      );
      provider.updateTask(updated);
    } else {
      provider.addTask(
        _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        reminderTime: _reminderTime,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isEdit ? 'Edit Task' : 'New Task',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),

          // Title
          TextField(
            controller: _titleCtrl,
            autofocus: !widget.isEdit,
            decoration: const InputDecoration(
              labelText: 'Task title *',
              prefixIcon: Icon(Icons.task_alt_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 12),

          // Description
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              prefixIcon: Icon(Icons.notes_rounded, size: 18),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          // Priority
          const Text(
            'Priority',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _priorityChip('Low', 0, Colors.grey),
              const SizedBox(width: 8),
              _priorityChip('Medium', 1, Colors.orange),
              const SizedBox(width: 8),
              _priorityChip('High', 2, Colors.red),
            ],
          ),
          const SizedBox(height: 12),

          // Due date + Reminder row
          Row(
            children: [
              Expanded(
                child: _optionButton(
                  icon: Icons.calendar_today_rounded,
                  label: _dueDate == null
                      ? 'Due date'
                      : DateFormat('MMM d, y').format(_dueDate!),
                  active: _dueDate != null,
                  color: Colors.blue,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _dueDate ??
                          DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                  onClear: _dueDate != null
                      ? () => setState(() => _dueDate = null)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _optionButton(
                  icon: Icons.notifications_rounded,
                  label: _reminderTime == null
                      ? 'Reminder'
                      : DateFormat('MMM d, h:mm a').format(_reminderTime!),
                  active: _reminderTime != null,
                  color: Colors.deepPurple,
                  onTap: _pickReminder,
                  onClear: _reminderTime != null
                      ? () => setState(() => _reminderTime = null)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Submit
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: Icon(
                widget.isEdit ? Icons.save_rounded : Icons.add_rounded,
              ),
              label: Text(widget.isEdit ? 'Save Changes' : 'Add Task'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityChip(String label, int val, Color color) {
    final isSelected = val == _priority;
    return GestureDetector(
      onTap: () => setState(() => _priority = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _optionButton({
    required IconData icon,
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.4) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: active ? color : Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: active ? color : Colors.grey[600],
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: color.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Reminder Picker Bottom Sheet ─────────────────────────────────────────────

class _ReminderPicker extends StatelessWidget {
  final DateTime? current;
  final ValueChanged<DateTime?> onSelected;

  const _ReminderPicker({this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final quickOptions = [
      _QuickOption(
        'In 30 minutes',
        Icons.timer_rounded,
        Colors.teal,
        now.add(const Duration(minutes: 30)),
      ),
      _QuickOption(
        'In 1 hour',
        Icons.schedule_rounded,
        Colors.blue,
        now.add(const Duration(hours: 1)),
      ),
      _QuickOption(
        'In 3 hours',
        Icons.access_time_rounded,
        Colors.indigo,
        now.add(const Duration(hours: 3)),
      ),
      _QuickOption(
        'Tonight 8 PM',
        Icons.nights_stay_rounded,
        Colors.deepPurple,
        DateTime(now.year, now.month, now.day, 20, 0),
      ),
      _QuickOption(
        'Tomorrow 9 AM',
        Icons.wb_sunny_rounded,
        Colors.orange,
        DateTime(now.year, now.month, now.day + 1, 9, 0),
      ),
      _QuickOption(
        'Tomorrow 6 PM',
        Icons.wb_twilight_rounded,
        Colors.amber,
        DateTime(now.year, now.month, now.day + 1, 18, 0),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.notifications_rounded,
                color: Colors.deepPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Set Reminder',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (current != null)
                TextButton(
                  onPressed: () {
                    onSelected(null);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Quick options grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3.5,
            ),
            itemCount: quickOptions.length,
            itemBuilder: (_, i) {
              final opt = quickOptions[i];
              final isSelected =
                  current != null &&
                  current!.difference(opt.time).abs() <
                      const Duration(minutes: 1);
              final isPast = opt.time.isBefore(DateTime.now());
              return GestureDetector(
                onTap: isPast
                    ? null
                    : () {
                        onSelected(opt.time);
                        Navigator.pop(context);
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.grey.withValues(alpha: 0.06)
                        : isSelected
                        ? opt.color.withValues(alpha: 0.15)
                        : opt.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPast
                          ? Colors.grey.withValues(alpha: 0.2)
                          : isSelected
                          ? opt.color
                          : opt.color.withValues(alpha: 0.25),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        opt.icon,
                        size: 15,
                        color: isPast ? Colors.grey : opt.color,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isPast ? Colors.grey : opt.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Custom date & time
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_calendar_rounded, size: 16),
              label: const Text('Custom date & time'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.deepPurple,
                side: const BorderSide(color: Colors.deepPurple, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _pickCustom(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustom(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour + 1, minute: 0),
    );
    if (time == null) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    onSelected(dt);
  }
}

class _QuickOption {
  final String label;
  final IconData icon;
  final Color color;
  final DateTime time;
  _QuickOption(this.label, this.icon, this.color, this.time);
}
