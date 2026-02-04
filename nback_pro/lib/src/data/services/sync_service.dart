import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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
  /// Database ID created in Firebase Console (Standard, nam5). All sync uses this DB.
  /// If logs still show "database (default) does not exist", the native SDK may open
  /// (default) eagerly; create a (default) database in Console (can be empty) to silence it.
  static const String _firestoreDatabaseId = 'nbackpro';

  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: _firestoreDatabaseId,
  );

  /// When true, Firestore database is missing (NOT_FOUND). Skip all ops to avoid log spam.
  static bool _firestoreUnavailable = false;

  static bool _isDatabaseMissing(Object e) {
    if (e is FirebaseException) {
      if (e.code == 'not-found') return true;
      final msg = e.message ?? '';
      if (msg.contains('does not exist') && msg.contains('database')) return true;
    }
    return false;
  }

  /// Pull users/{uid} data and sessions into local repos. Call after sign-in and on app start when signed in.
  Future<void> pull(
    String uid,
    SettingsRepository settingsRepo,
    StatsRepository statsRepo,
  ) async {
    if (_firestoreUnavailable) return;
    // #region agent log
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    _debugLog('pull entry', {'uid': uid, 'authUid': authUid, 'databaseId': _firestoreDatabaseId}, 'B,C');
    // #endregion
    try {
      // #region agent log
      _debugLog('pull before get', {'uid': uid}, 'A,D,E');
      // #endregion
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final data = userDoc.data();

      if (data != null) {
        final settingsMap = data['settings'] as Map<String, dynamic>?;
        if (settingsMap != null) {
          await settingsRepo.saveSettings(UserSettings.fromMap(settingsMap));
        }
        final streakMap = data['streak'] as Map<String, dynamic>?;
        if (streakMap != null) {
          final serverStreak = UserStreak.fromMap(streakMap);
          final localStreak = await statsRepo.getStreak();
          final useServer = serverStreak.lastCompletedDate != null &&
              (localStreak.lastCompletedDate == null ||
                  (serverStreak.lastCompletedDate!
                          .isAfter(localStreak.lastCompletedDate!) &&
                      serverStreak.currentStreak >= localStreak.currentStreak));
          if (useServer) {
            await statsRepo.saveStreak(serverStreak);
          }
        }
      }

      final sessionsSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .orderBy('date', descending: true)
          .get();

      final serverSessions = sessionsSnap.docs
          .map((d) => SessionResult.fromMap(d.data()))
          .toList();

      final localSessions = await statsRepo.getAllSessions();
      final seen = <String>{};
      final merged = <SessionResult>[];
      for (final s in [...serverSessions, ...localSessions]) {
        final key =
            '${s.date.millisecondsSinceEpoch ~/ 60000}_${s.nLevel}_${s.accuracy.toStringAsFixed(2)}';
        if (seen.add(key)) merged.add(s);
      }
      merged.sort((a, b) => b.date.compareTo(a.date));
      if (merged.isNotEmpty) {
        await statsRepo.replaceAllSessions(merged);
      }
    } catch (e) {
      // #region agent log
      final code = e is FirebaseException ? e.code : null;
      final msg = e.toString();
      _debugLog('pull catch', {'error': msg, 'code': code}, 'A,B,E');
      // #endregion
      if (_isDatabaseMissing(e)) _firestoreUnavailable = true;
      // Offline or permission: ignore; local data remains
    }
  }

  // #region agent log
  static void _debugLog(String message, Map<String, dynamic> data, String hypothesisId) {
    final payload = {
      'sessionId': 'debug-session',
      'hypothesisId': hypothesisId,
      'location': 'sync_service.dart:pull',
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    Future<void> send() async {
      try {
        final req = await HttpClient().postUrl(Uri.parse('http://$host:7244/ingest/7778e214-e526-4aed-902b-ea02383967f3'));
        req.headers.contentType = ContentType('application', 'json');
        req.write(jsonEncode(payload));
        await req.close();
      } catch (_) {}
    }
    unawaited(send());
  }
  // #endregion

  /// Push settings to Firestore. Call when signed in after saving settings locally.
  Future<void> pushSettings(String uid, UserSettings settings) async {
    if (_firestoreUnavailable) return;
    try {
      await _firestore.collection('users').doc(uid).set(
            {'settings': settings.toMap()},
            SetOptions(merge: true),
          );
    } catch (e) {
      if (_isDatabaseMissing(e)) _firestoreUnavailable = true;
    }
  }

  /// Push streak to Firestore. Call when signed in after saving streak locally.
  Future<void> pushStreak(String uid, UserStreak streak) async {
    if (_firestoreUnavailable) return;
    try {
      await _firestore.collection('users').doc(uid).set(
            {'streak': streak.toMap()},
            SetOptions(merge: true),
          );
    } catch (e) {
      if (_isDatabaseMissing(e)) _firestoreUnavailable = true;
    }
  }

  /// Push one session to Firestore. Call when signed in after saving session locally.
  Future<void> pushSession(String uid, SessionResult session) async {
    if (_firestoreUnavailable) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .add(session.toMap());
    } catch (e) {
      if (_isDatabaseMissing(e)) _firestoreUnavailable = true;
    }
  }

  /// Deletes all cloud data for the user (settings, streak, sessions). Call before sign-out on reset.
  Future<void> deleteUserData(String uid) async {
    if (_firestoreUnavailable) return;
    try {
      final sessionsSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .get();
      for (final doc in sessionsSnap.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      if (_isDatabaseMissing(e)) _firestoreUnavailable = true;
    }
  }
}
