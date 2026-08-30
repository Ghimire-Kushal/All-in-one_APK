import 'package:ecommerce_app/models/clipboard_item.dart';
import 'package:ecommerce_app/models/expense.dart';
import 'package:ecommerce_app/models/note.dart';
import 'package:ecommerce_app/models/password_entry.dart';
import 'package:ecommerce_app/models/task.dart';
import 'package:ecommerce_app/models/timetable_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 30, 12, 30);

  test('clipboard item retains every value through JSON', () {
    final item = ClipboardItem(
      id: 'clip-1',
      text: 'Important text',
      isPinned: true,
      createdAt: createdAt,
    );

    final restored = ClipboardItem.fromJson(item.toJson());
    expect(restored.id, item.id);
    expect(restored.text, item.text);
    expect(restored.isPinned, isTrue);
    expect(restored.createdAt, createdAt);
  });

  test(
    'expense restores valid categories and safely defaults unknown ones',
    () {
      final expense = Expense(
        id: 'expense-1',
        title: 'Bus',
        amount: 42.5,
        category: ExpenseCategory.travel,
        date: createdAt,
        note: 'Campus',
      );

      final restored = Expense.fromJson(expense.toJson());
      expect(restored.category, ExpenseCategory.travel);
      expect(restored.amount, 42.5);

      final unknown = Expense.fromJson({
        ...expense.toJson(),
        'category': 'legacy',
      });
      expect(unknown.category, ExpenseCategory.other);
    },
  );

  test(
    'note, password entry, and task retain optional values through JSON',
    () {
      final note = Note(
        id: 'note-1',
        title: 'Plan',
        content: 'Study',
        isPinned: true,
        createdAt: createdAt,
        updatedAt: createdAt.add(const Duration(minutes: 5)),
        colorHex: '#123456',
      );
      final password = PasswordEntry(
        id: 'password-1',
        title: 'Portal',
        username: 'student',
        password: 'secret',
        website: 'https://example.test',
        note: 'School',
        createdAt: createdAt,
      );
      final task = Task(
        id: 'task-1',
        title: 'Submit report',
        description: 'Before noon',
        isCompleted: true,
        priority: 2,
        dueDate: createdAt,
        reminderTime: createdAt.subtract(const Duration(hours: 1)),
        createdAt: createdAt,
      );

      expect(Note.fromJson(note.toJson()).colorHex, '#123456');
      expect(
        PasswordEntry.fromJson(password.toJson()).website,
        password.website,
      );
      final restoredTask = Task.fromJson(task.toJson());
      expect(restoredTask.dueDate, task.dueDate);
      expect(restoredTask.reminderTime, task.reminderTime);
    },
  );

  test('timetable entries serialize, format time, and copy safely', () {
    final entry = TimetableEntry(
      id: 'class-1',
      title: 'Math',
      notes: 'Room 3',
      days: [1, 3, 5],
      startHour: 13,
      startMinute: 5,
      endHour: 14,
      endMinute: 0,
    );

    final restored = TimetableEntry.fromJson(entry.toJson());
    expect(restored.startLabel, '1:05 PM');
    expect(restored.endLabel, '2:00 PM');
    expect(restored.isEveryDay, isFalse);
    expect(restored.copyWith(title: 'Physics').title, 'Physics');
    expect(restored.copyWith().days, isNot(same(entry.days)));
  });
}
