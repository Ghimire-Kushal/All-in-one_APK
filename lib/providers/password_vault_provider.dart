import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/password_entry.dart';

class PasswordVaultProvider extends ChangeNotifier {
  static const _entriesKey = 'vault_entries';
  static const _pinKey = 'vault_pin';
  final _uuid = const Uuid();

  List<PasswordEntry> _entries = [];
  bool _isUnlocked = false;
  bool _hasPin = false;

  List<PasswordEntry> get entries => _entries;
  bool get isUnlocked => _isUnlocked;
  bool get hasPin => _hasPin;

  PasswordVaultProvider() {
    _checkPin();
  }

  Future<void> _checkPin() async {
    final prefs = await SharedPreferences.getInstance();
    _hasPin = prefs.getString(_pinKey) != null;
    notifyListeners();
  }

  Future<bool> setPin(String pin) async {
    if (pin.length < 4) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    _hasPin = true;
    _isUnlocked = true;
    notifyListeners();
    return true;
  }

  Future<bool> unlock(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinKey);
    if (stored == pin) {
      _isUnlocked = true;
      await _load();
      notifyListeners();
      return true;
    }
    return false;
  }

  void lock() {
    _isUnlocked = false;
    _entries = [];
    notifyListeners();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_entriesKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _entries = list
          .map((e) => PasswordEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _entriesKey,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addEntry(
    String title,
    String username,
    String password, {
    String website = '',
    String note = '',
  }) async {
    _entries.insert(
      0,
      PasswordEntry(
        id: _uuid.v4(),
        title: title,
        username: username,
        password: password,
        website: website,
        note: note,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    await _save();
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> updateEntry(PasswordEntry entry) async {
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      _entries[idx] = entry;
      notifyListeners();
      await _save();
    }
  }
}
