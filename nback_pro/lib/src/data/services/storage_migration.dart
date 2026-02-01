import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_result.dart';
import '../models/user_settings.dart';
import '../models/user_streak.dart';

const String _migrationDoneKey = 'storage_migration_v1_done';
const String _settingsKey = 'user_settings';
const String _streakKey = 'user_streak';

/// One-time migration: copy legacy boxes (settings, sessions, streak) to guest-scoped boxes
/// so existing users see their data as guest. Run after Hive.initFlutter() and registerAdapters.
Future<void> runStorageMigrationIfNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_migrationDoneKey) == true) return;

  if (await Hive.boxExists('settings') != true) {
    await prefs.setBool(_migrationDoneKey, true);
    return;
  }

  await _migrateSettings();
  await _migrateSessions();
  await _migrateStreak();

  await prefs.setBool(_migrationDoneKey, true);
}

Future<void> _migrateSettings() async {
  if (Hive.isBoxOpen('settings') != true) {
    await Hive.openBox<UserSettings>('settings');
  }
  final oldBox = Hive.box<UserSettings>('settings');
  final stored = oldBox.get(_settingsKey);
  await oldBox.close();

  final newBox = await Hive.openBox<UserSettings>('settings_guest');
  if (stored != null) {
    await newBox.put(_settingsKey, UserSettings.fromMap(stored.toMap()));
  }
  await newBox.close();

  await Hive.deleteBoxFromDisk('settings');
}

Future<void> _migrateSessions() async {
  if (await Hive.boxExists('sessions') != true) {
    return;
  }
  if (Hive.isBoxOpen('sessions') != true) {
    await Hive.openBox<SessionResult>('sessions');
  }
  final oldBox = Hive.box<SessionResult>('sessions');
  final sessions = oldBox.values.toList();
  await oldBox.close();

  if (sessions.isNotEmpty) {
    final newBox = await Hive.openBox<SessionResult>('sessions_guest');
    for (final s in sessions) {
      await newBox.add(SessionResult.fromMap(s.toMap()));
    }
    await newBox.close();
  }

  await Hive.deleteBoxFromDisk('sessions');
}

Future<void> _migrateStreak() async {
  if (await Hive.boxExists('streak') != true) {
    return;
  }
  if (Hive.isBoxOpen('streak') != true) {
    await Hive.openBox<UserStreak>('streak');
  }
  final oldBox = Hive.box<UserStreak>('streak');
  final stored = oldBox.get(_streakKey);
  await oldBox.close();

  final newBox = await Hive.openBox<UserStreak>('streak_guest');
  if (stored != null) {
    await newBox.put(_streakKey, UserStreak.fromMap(stored.toMap()));
  }
  await newBox.close();

  await Hive.deleteBoxFromDisk('streak');
}
