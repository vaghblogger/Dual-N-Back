import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/session_result.dart';
import '../models/user_settings.dart';
import '../models/user_streak.dart';
import '../repositories/settings_repository.dart';
import '../repositories/stats_repository.dart';

/// Cloud sync for signed-in users: pull from Firestore into local repos, push on save.
/// Guest: no Firestore read/write.
///
/// Firestore structure: users/{uid} (doc: settings, streak), users/{uid}/sessions (subcollection).
/// Security: deploy [firestore.rules] so only request.auth.uid == uid can read/write.
class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Pull users/{uid} data and sessions into local repos. Call after sign-in and on app start when signed in.
  Future<void> pull(
    String uid,
    SettingsRepository settingsRepo,
    StatsRepository statsRepo,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final data = userDoc.data();

      if (data != null) {
        final settingsMap = data['settings'] as Map<String, dynamic>?;
        if (settingsMap != null) {
          await settingsRepo.saveSettings(UserSettings.fromMap(settingsMap));
        }
        final streakMap = data['streak'] as Map<String, dynamic>?;
        if (streakMap != null) {
          await statsRepo.saveStreak(UserStreak.fromMap(streakMap));
        }
      }

      final sessionsSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .orderBy('date', descending: true)
          .get();

      final sessions = sessionsSnap.docs
          .map((d) => SessionResult.fromMap(d.data()))
          .toList();
      if (sessions.isNotEmpty) {
        await statsRepo.replaceAllSessions(sessions);
      }
    } catch (_) {
      // Offline or permission: ignore; local data remains
    }
  }

  /// Push settings to Firestore. Call when signed in after saving settings locally.
  Future<void> pushSettings(String uid, UserSettings settings) async {
    try {
      await _firestore.collection('users').doc(uid).set(
            {'settings': settings.toMap()},
            SetOptions(merge: true),
          );
    } catch (_) {}
  }

  /// Push streak to Firestore. Call when signed in after saving streak locally.
  Future<void> pushStreak(String uid, UserStreak streak) async {
    try {
      await _firestore.collection('users').doc(uid).set(
            {'streak': streak.toMap()},
            SetOptions(merge: true),
          );
    } catch (_) {}
  }

  /// Push one session to Firestore. Call when signed in after saving session locally.
  Future<void> pushSession(String uid, SessionResult session) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .add(session.toMap());
    } catch (_) {}
  }
}
