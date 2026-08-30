import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  static const _prefKey = 'expense_data';
  final _uuid = const Uuid();
  List<Expense> _expenses = [];
  String? _uid;
  StreamSubscription<QuerySnapshot>? _fsSub;
  StreamSubscription<User?>? _authSub;
  bool _isDisposed = false;
  int _authGeneration = 0;

  List<Expense> get expenses => _expenses;

  ExpenseProvider() {
    _load();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authGeneration++;
    _authSub?.cancel();
    _fsSub?.cancel();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('expenses');

  void _onAuthChanged(User? user) async {
    final generation = ++_authGeneration;
    await _fsSub?.cancel();
    if (_isDisposed || generation != _authGeneration) return;
    _fsSub = null;
    final uid = user?.uid;
    _uid = uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    if (_isDisposed || generation != _authGeneration || _uid != uid) return;
    final syncKey = 'expenses_synced_$uid';
    final hasSynced = prefs.getBool(syncKey) ?? false;

    if (!hasSynced && _expenses.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final e in _expenses) {
        batch.set(_col(uid).doc(e.id), e.toJson());
      }
      await batch.commit();
      if (_isDisposed || generation != _authGeneration || _uid != uid) return;
    }
    await prefs.setBool(syncKey, true);
    if (_isDisposed || generation != _authGeneration || _uid != uid) return;

    _fsSub = _col(uid).snapshots().listen((snap) {
      if (_isDisposed || generation != _authGeneration || _uid != uid) return;
      _expenses = snap.docs.map((d) => Expense.fromJson(d.data())).toList();
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      _saveLocal();
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _expenses = list
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode(_expenses.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveRemote(Expense expense) async {
    if (_uid == null) return;
    await _col(_uid!).doc(expense.id).set(expense.toJson());
  }

  Future<void> _deleteRemote(String id) async {
    if (_uid == null) return;
    await _col(_uid!).doc(id).delete();
  }

  Future<void> addExpense(
    String title,
    double amount,
    ExpenseCategory category, {
    String note = '',
    DateTime? date,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      category: category,
      date: date ?? DateTime.now(),
      note: note,
    );
    _expenses.insert(0, expense);
    notifyListeners();
    await _saveLocal();
    await _saveRemote(expense);
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
    await _saveLocal();
    await _deleteRemote(id);
  }

  List<Expense> getByMonth(int year, int month) => _expenses
      .where((e) => e.date.year == year && e.date.month == month)
      .toList();

  double totalByMonth(int year, int month) =>
      getByMonth(year, month).fold(0.0, (total, e) => total + e.amount);

  double get totalToday {
    final now = DateTime.now();
    return _expenses
        .where(
          (e) =>
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day,
        )
        .fold(0.0, (total, e) => total + e.amount);
  }

  Map<ExpenseCategory, double> categoryTotals(int year, int month) {
    final map = <ExpenseCategory, double>{};
    for (final e in getByMonth(year, month)) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }
}
