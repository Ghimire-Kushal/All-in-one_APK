import 'package:flutter/material.dart';
import 'notes/notes_screen.dart';
import 'todo/todo_screen.dart';
import 'expense/expense_screen.dart';
import 'timetable/timetable_screen.dart';
import '../core/theme/app_theme.dart';

class ProductivityTab extends StatelessWidget {
  const ProductivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity', style: TextStyle(fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildBigCard(
            context,
            'Notes & Memos',
            'Write, pin, and search notes',
            Icons.sticky_note_2_rounded,
            AppColors.notes,
            const NotesScreen(),
          ),
          const SizedBox(height: 12),
          _buildBigCard(
            context,
            'To-Do / Task Planner',
            'Manage tasks with priorities',
            Icons.checklist_rounded,
            AppColors.todo,
            const TodoScreen(),
          ),
          const SizedBox(height: 12),
          _buildBigCard(
            context,
            'Expense Tracker',
            'Track daily spending with charts',
            Icons.account_balance_wallet_rounded,
            AppColors.expense,
            const ExpenseScreen(),
          ),
          const SizedBox(height: 12),
          _buildBigCard(
            context,
            'Timetable',
            'Weekly class schedule with reminders',
            Icons.calendar_view_week_rounded,
            AppColors.timetable,
            const TimetableScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildBigCard(BuildContext context, String title, String subtitle,
      IconData icon, Color color, Widget screen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1F2A) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
