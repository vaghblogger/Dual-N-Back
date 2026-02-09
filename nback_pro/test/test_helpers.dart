import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:nback_pro/src/data/models/session_result.dart';
import 'package:nback_pro/src/data/models/user_settings.dart';
import 'package:nback_pro/src/data/models/user_streak.dart';
import 'package:nback_pro/src/data/repositories/settings_repository.dart';
import 'package:nback_pro/src/data/repositories/stats_repository.dart';
import 'package:nback_pro/src/data/services/auth_service.dart';
import 'package:nback_pro/src/logic/providers/auth_provider.dart';
import 'package:nback_pro/src/logic/providers/game_provider.dart';
import 'package:nback_pro/src/logic/providers/settings_provider.dart';
import 'package:nback_pro/src/logic/providers/subscription_provider.dart';

/// Unique test user id for Hive box isolation. Increment per test if needed.
int _testUserIdCounter = 0;

String get nextTestUserId => 'test_user_${_testUserIdCounter++}';

/// Initializes Hive for tests with a temp directory and registers adapters.
/// Call in setUpAll() of test groups that use repositories.
Future<void> initHiveForTest() async {
  final dir = await Directory.systemTemp.createTemp('nback_hive_test_');
  Hive.init(dir.path);
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserSettingsAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(SessionResultAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(UserStreakAdapter());
  }
}

/// Closes Hive. Call in tearDownAll() if needed.
Future<void> closeHiveForTest() async {
  await Hive.close();
}

/// Provider overrides for widget/unit tests: guest user, default settings, premium off.
List<Override> testOverrides({
  User? currentUser,
  UserSettings? settings,
  bool isPremium = false,
}) {
  final userId = currentUser?.uid ?? 'guest';
  return [
    authServiceProvider.overrideWithValue(
      MockAuthService(currentUser: currentUser),
    ),
    settingsRepositoryProvider.overrideWithValue(
      SettingsRepository(userId),
    ),
    statsRepositoryProvider.overrideWithValue(
      StatsRepository(userId),
    ),
    if (settings != null)
      settingsProvider.overrideWith(() => FakeSettingsNotifier(settings)),
    isPremiumProvider.overrideWithValue(isPremium),
  ];
}

/// Mock AuthService that exposes a fixed current user and stream.
class MockAuthService implements AuthService {
  MockAuthService({this.currentUser});

  @override
  final User? currentUser;

  @override
  bool get isGuest => currentUser == null;

  @override
  String? get displayName =>
      currentUser?.displayName ?? currentUser?.email;

  @override
  Stream<User?> get authStateChanges => Stream.value(currentUser);

  @override
  Future<User?> signInWithGoogle() async => currentUser;

  @override
  Future<User?> signInWithApple() async => currentUser;

  @override
  Future<void> signOut() async {}
}

/// Fake SettingsNotifier that returns a fixed value (for widget tests).
class FakeSettingsNotifier extends SettingsNotifier {
  FakeSettingsNotifier(this._s);

  final UserSettings _s;

  @override
  Future<UserSettings> build() async => _s;
}

/// In-memory fake for SettingsRepository (for router/widget tests that avoid Hive).
class FakeSettingsRepository extends SettingsRepository {
  FakeSettingsRepository(super.userId);

  UserSettings? _store;

  @override
  Future<UserSettings> getSettings() async => _store ?? UserSettings();

  @override
  Future<void> saveSettings(UserSettings settings) async {
    _store = settings;
  }

  @override
  Future<void> closeAndDeleteAll() async {
    _store = null;
  }
}
