import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppAuthProvider extends ChangeNotifier {
  AppAuthProvider() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }

  User? get user => FirebaseAuth.instance.currentUser;
  bool get isSignedIn => user != null;

  String get displayName {
    final u = user;
    if (u == null) return 'Guest';
    final raw = u.displayName?.trim().isNotEmpty == true
        ? u.displayName!.trim()
        : u.email?.split('@').first ?? 'Guest';
    return raw
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String get email => user?.email ?? '';

  Future<void> signOut() => FirebaseAuth.instance.signOut();
}
