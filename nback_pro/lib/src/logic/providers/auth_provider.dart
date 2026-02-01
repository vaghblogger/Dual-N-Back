import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Stream of Firebase auth state. Use this so UI (e.g. Settings) reacts to sign-in/sign-out.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Current Firebase user, derived from auth stream. Null when not logged in with Google.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateChangesProvider).valueOrNull;
});

/// Storage user ID for per-user local data: Firebase uid when signed in, 'guest' otherwise.
/// Sanitized for Hive box names (only [a-zA-Z0-9_]).
final currentStorageUserIdProvider = Provider<String>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null || uid.isEmpty) return 'guest';
  return uid.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
});
