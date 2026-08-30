import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';

class NotesProvider extends ChangeNotifier {
  static const _prefKey = 'notes_data';
  final _uuid = const Uuid();
  List<Note> _notes = [];
  String? _uid;
  StreamSubscription<QuerySnapshot>? _fsSub;

  List<Note> get notes => _notes;
  List<Note> get pinnedNotes => _notes.where((n) => n.isPinned).toList();
  List<Note> get unpinnedNotes => _notes.where((n) => !n.isPinned).toList();

  NotesProvider() {
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
          .collection('notes');

  void _onAuthChanged(User? user) async {
    await _fsSub?.cancel();
    _fsSub = null;
    _uid = user?.uid;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final syncKey = 'notes_synced_${user.uid}';
    final hasSynced = prefs.getBool(syncKey) ?? false;

    if (!hasSynced && _notes.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final n in _notes) {
        batch.set(_col(user.uid).doc(n.id), n.toJson());
      }
      await batch.commit();
    }
    await prefs.setBool(syncKey, true);

    _fsSub = _col(user.uid).snapshots().listen((snap) {
      _notes = snap.docs.map((d) => Note.fromJson(d.data())).toList();
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
      _notes = list
          .map((e) => Note.fromJson(e as Map<String, dynamic>))
          .toList();
      _sort();
      notifyListeners();
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode(_notes.map((n) => n.toJson()).toList()),
    );
  }

  Future<void> _saveRemote(Note note) async {
    if (_uid == null) return;
    await _col(_uid!).doc(note.id).set(note.toJson());
  }

  Future<void> _deleteRemote(String id) async {
    if (_uid == null) return;
    await _col(_uid!).doc(id).delete();
  }

  void _sort() {
    _notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  Future<void> addNote(
    String title,
    String content, {
    String colorHex = '#FFFFFF',
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      colorHex: colorHex,
    );
    _notes.insert(0, note);
    _sort();
    notifyListeners();
    await _saveLocal();
    await _saveRemote(note);
  }

  Future<void> updateNote(Note note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx == -1) return;
    note.updatedAt = DateTime.now();
    _notes[idx] = note;
    _sort();
    notifyListeners();
    await _saveLocal();
    await _saveRemote(note);
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveLocal();
    await _deleteRemote(id);
  }

  Future<void> togglePin(String id) async {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notes[idx].isPinned = !_notes[idx].isPinned;
    final note = _notes[idx];
    _sort();
    notifyListeners();
    await _saveLocal();
    await _saveRemote(note);
  }

  List<Note> search(String query) {
    final q = query.toLowerCase();
    return _notes
        .where(
          (n) =>
              n.title.toLowerCase().contains(q) ||
              n.content.toLowerCase().contains(q),
        )
        .toList();
  }
}
