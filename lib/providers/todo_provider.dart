import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

class TodoProvider extends ChangeNotifier {
  static const _prefKey = 'todo_data';
  final _uuid = const Uuid();
  List<Task> _tasks = [];
  String? _uid;
  StreamSubscription<QuerySnapshot>? _fsSub;

  List<Task> get tasks => _tasks;
  List<Task> get pending =>
      _tasks.where((t) => !t.isCompleted).toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));
  List<Task> get completed => _tasks.where((t) => t.isCompleted).toList();

  TodoProvider() {
    _load();
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _fsSub?.cancel();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks');

  void _onAuthChanged(User? user) async {
    await _fsSub?.cancel();
    _fsSub = null;
    _uid = user?.uid;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final syncKey = 'tasks_synced_${user.uid}';
    final hasSynced = prefs.getBool(syncKey) ?? false;

    if (!hasSynced && _tasks.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final t in _tasks) {
        batch.set(_col(user.uid).doc(t.id), t.toJson());
      }
      await batch.commit();
    }
    await prefs.setBool(syncKey, true);

    _fsSub = _col(user.uid).snapshots().listen((snap) {
      _tasks = snap.docs.map((d) => Task.fromJson(d.data())).toList();
      notifyListeners();
      _saveLocal();
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _tasks = list
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final task in _tasks) {
        if (!task.isCompleted &&
            task.reminderTime != null &&
            task.reminderTime!.isAfter(DateTime.now())) {
          _scheduleReminder(task);
        }
      }
      notifyListeners();
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode(_tasks.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> _saveRemote(Task task) async {
    if (_uid == null) return;
    await _col(_uid!).doc(task.id).set(task.toJson());
  }

  Future<void> _deleteRemote(String id) async {
    if (_uid == null) return;
    await _col(_uid!).doc(id).delete();
  }

  void _scheduleReminder(Task task) {
    if (task.reminderTime == null) return;
    NotificationService().scheduleReminder(
      id: NotificationService().idFromTaskId(task.id),
      taskTitle: task.title,
      scheduledTime: task.reminderTime!,
    );
  }

  void _cancelReminder(String taskId) =>
      NotificationService().cancel(NotificationService().idFromTaskId(taskId));

  Future<void> addTask(
    String title, {
    String description = '',
    int priority = 1,
    DateTime? dueDate,
    DateTime? reminderTime,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      reminderTime: reminderTime,
      createdAt: DateTime.now(),
    );
    _tasks.insert(0, task);
    if (reminderTime != null) _scheduleReminder(task);
    notifyListeners();
    await _saveLocal();
    await _saveRemote(task);
  }

  Future<void> toggleComplete(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _tasks[idx].isCompleted = !_tasks[idx].isCompleted;
    if (_tasks[idx].isCompleted) _cancelReminder(id);
    final task = _tasks[idx];
    notifyListeners();
    await _saveLocal();
    await _saveRemote(task);
  }

  Future<void> deleteTask(String id) async {
    _cancelReminder(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _saveLocal();
    await _deleteRemote(id);
  }

  Future<void> updateTask(Task task) async {
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx == -1) return;
    _cancelReminder(task.id);
    _tasks[idx] = task;
    if (!task.isCompleted && task.reminderTime != null) _scheduleReminder(task);
    notifyListeners();
    await _saveLocal();
    await _saveRemote(task);
  }

  Future<void> clearCompleted() async {
    for (final t in _tasks.where((t) => t.isCompleted)) {
      _cancelReminder(t.id);
    }
    final toDelete = _tasks
        .where((t) => t.isCompleted)
        .map((t) => t.id)
        .toList();
    _tasks.removeWhere((t) => t.isCompleted);
    notifyListeners();
    await _saveLocal();
    if (_uid != null) {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in toDelete) {
        batch.delete(_col(_uid!).doc(id));
      }
      await batch.commit();
    }
  }
}
