import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/timetable_entry.dart';
import '../services/notification_service.dart';

class TimetableProvider extends ChangeNotifier {
  static const _prefKey = 'timetable_data_v2';
  final _uuid = const Uuid();
  List<TimetableEntry> _entries = [];

  List<TimetableEntry> get entries => List.unmodifiable(_entries);

  List<TimetableEntry> forDay(int dayOfWeek) =>
      _entries.where((e) => e.days.contains(dayOfWeek)).toList()
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

  List<TimetableEntry> get todayEntries => forDay(DateTime.now().weekday);

  TimetableEntry? get nextTodayEntry {
    final nowMin = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
    return todayEntries
        .where((e) => e.startMinutes > nowMin)
        .fold<TimetableEntry?>(
          null,
          (prev, e) =>
              prev == null || e.startMinutes < prev.startMinutes ? e : prev,
        );
  }

  TimetableProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _entries = list
          .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
      for (final entry in _entries) {
        if (entry.notifyEnabled) _scheduleAll(entry);
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addEntry(TimetableEntry entry) async {
    _entries.add(entry);
    notifyListeners();
    await _save();
    if (entry.notifyEnabled) _scheduleAll(entry);
  }

  Future<void> updateEntry(TimetableEntry updated) async {
    final idx = _entries.indexWhere((e) => e.id == updated.id);
    if (idx == -1) return;
    _cancelAll(_entries[idx]);
    _entries[idx] = updated;
    notifyListeners();
    await _save();
    if (updated.notifyEnabled) _scheduleAll(updated);
  }

  Future<void> deleteEntry(String id) async {
    final entry = _entries.firstWhere(
      (e) => e.id == id,
      orElse: () => throw StateError('not found'),
    );
    _cancelAll(entry);
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _save();
  }

  TimetableEntry buildNew({
    required String title,
    String? notes,
    required int categoryIndex,
    required List<int> days,
    required int startHour,
    required int startMinute,
    int? endHour,
    int? endMinute,
    required String colorHex,
    required bool notifyEnabled,
    required int notifyMinutesBefore,
  }) => TimetableEntry(
    id: _uuid.v4(),
    title: title,
    notes: notes,
    categoryIndex: categoryIndex,
    days: days,
    startHour: startHour,
    startMinute: startMinute,
    endHour: endHour,
    endMinute: endMinute,
    colorHex: colorHex,
    notifyEnabled: notifyEnabled,
    notifyMinutesBefore: notifyMinutesBefore,
  );

  // Each entry × weekday gets its own notification ID so they don't collide.
  int _notifId(String entryId, int weekday) =>
      (entryId.hashCode.abs() % 100000000) * 10 + weekday;

  void _scheduleAll(TimetableEntry entry) {
    for (final day in entry.days) {
      NotificationService().scheduleTimetableReminder(
        id: _notifId(entry.id, day),
        subject: entry.title,
        classWeekday: day,
        classHour: entry.startHour,
        classMinute: entry.startMinute,
        notifyMinutesBefore: entry.notifyMinutesBefore,
      );
    }
  }

  void _cancelAll(TimetableEntry entry) {
    for (final day in entry.days) {
      NotificationService().cancelTimetableReminder(_notifId(entry.id, day));
    }
  }
}
