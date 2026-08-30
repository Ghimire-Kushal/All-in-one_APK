import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/clipboard_item.dart';

class ClipboardProvider extends ChangeNotifier {
  static const _prefKey = 'clipboard_data';
  final _uuid = const Uuid();
  List<ClipboardItem> _items = [];
  String? _uid;
  StreamSubscription<QuerySnapshot>? _fsSub;
  StreamSubscription<User?>? _authSub;
  bool _isDisposed = false;
  int _authGeneration = 0;

  List<ClipboardItem> get items => _items;
  List<ClipboardItem> get pinned => _items.where((i) => i.isPinned).toList();
  List<ClipboardItem> get unpinned => _items.where((i) => !i.isPinned).toList();

  ClipboardProvider() {
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
          .collection('clipboard');

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
    final syncKey = 'clipboard_synced_$uid';
    final hasSynced = prefs.getBool(syncKey) ?? false;

    if (!hasSynced && _items.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final item in _items) {
        batch.set(_col(uid).doc(item.id), item.toJson());
      }
      await batch.commit();
      if (_isDisposed || generation != _authGeneration || _uid != uid) return;
    }
    await prefs.setBool(syncKey, true);
    if (_isDisposed || generation != _authGeneration || _uid != uid) return;

    _fsSub = _col(uid).snapshots().listen((snap) {
      if (_isDisposed || generation != _authGeneration || _uid != uid) return;
      _items = snap.docs.map((d) => ClipboardItem.fromJson(d.data())).toList();
      _sort();
      notifyListeners();
      _saveLocal();
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _items = list
          .map((e) => ClipboardItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _sort();
      notifyListeners();
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode(_items.map((i) => i.toJson()).toList()),
    );
  }

  Future<void> _saveRemote(ClipboardItem item) async {
    if (_uid == null) return;
    await _col(_uid!).doc(item.id).set(item.toJson());
  }

  Future<void> _deleteRemote(String id) async {
    if (_uid == null) return;
    await _col(_uid!).doc(id).delete();
  }

  void _sort() {
    _items.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<void> addItem(String text) async {
    if (text.trim().isEmpty) return;
    if (_items.any((i) => i.text == text)) return;
    final item = ClipboardItem(
      id: _uuid.v4(),
      text: text,
      createdAt: DateTime.now(),
    );
    _items.insert(0, item);
    _sort();
    notifyListeners();
    await _saveLocal();
    await _saveRemote(item);
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
    await _saveLocal();
    await _deleteRemote(id);
  }

  Future<void> togglePin(String id) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    _items[idx].isPinned = !_items[idx].isPinned;
    final item = _items[idx];
    _sort();
    notifyListeners();
    await _saveLocal();
    await _saveRemote(item);
  }

  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> clearAll() async {
    final toDelete = _items.where((i) => !i.isPinned).map((i) => i.id).toList();
    _items.removeWhere((i) => !i.isPinned);
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
