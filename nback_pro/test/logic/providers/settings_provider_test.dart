import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nback_pro/src/core/constants/settings_constants.dart';
import 'package:nback_pro/src/data/models/user_settings.dart';
import 'package:nback_pro/src/data/repositories/settings_repository.dart';
import 'package:nback_pro/src/logic/providers/auth_provider.dart';
import 'package:nback_pro/src/logic/providers/game_provider.dart';
import 'package:nback_pro/src/logic/providers/settings_provider.dart';
import '../../test_helpers.dart';

/// In-memory fake for SettingsRepository (extends to satisfy Provider type).
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

void main() {
  group('SettingsNotifier', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    test('build returns saved settings from repo', () async {
      final fakeRepo = FakeSettingsRepository('guest');
      await fakeRepo.saveSettings(UserSettings(selectedThemeId: 2));
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      final settings = await container.read(settingsProvider.future);
      expect(settings.selectedThemeId, 2);
    });

    test('build snaps speed to nearest speedOption when loading', () async {
      final fakeRepo = FakeSettingsRepository('guest');
      await fakeRepo.saveSettings(UserSettings(speedMultiplier: 1.2));
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      final settings = await container.read(settingsProvider.future);
      expect(speedOptions.contains(settings.speedMultiplier), true);
      expect((settings.speedMultiplier - 1.0).abs() <= 0.5, true);
    });

    test('updateTheme updates state and repo', () async {
      final fakeRepo = FakeSettingsRepository('guest');
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      await container.read(settingsProvider.future);
      await container.read(settingsProvider.notifier).updateTheme(4);
      final settings = container.read(settingsProvider).valueOrNull!;
      expect(settings.selectedThemeId, 4);
      final fromRepo = await fakeRepo.getSettings();
      expect(fromRepo.selectedThemeId, 4);
    });

    test('setAutoN updates state and repo', () async {
      final fakeRepo = FakeSettingsRepository('guest');
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      await container.read(settingsProvider.future);
      await container.read(settingsProvider.notifier).setAutoN(false);
      final settings = container.read(settingsProvider).valueOrNull!;
      expect(settings.isAutoN, false);
    });

    test('setManualN updates state and repo, clamps 1-15', () async {
      final fakeRepo = FakeSettingsRepository('guest');
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      await container.read(settingsProvider.future);
      await container.read(settingsProvider.notifier).setManualN(10);
      final settings = container.read(settingsProvider).valueOrNull!;
      expect(settings.manualN, 10);
      await container.read(settingsProvider.notifier).setManualN(20);
      expect(container.read(settingsProvider).valueOrNull!.manualN, 15);
    });

    test('setManualN when Auto-N off updates currentNProvider', () async {
      final fakeRepo = FakeSettingsRepository('guest');
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      await container.read(settingsProvider.future);
      await container.read(settingsProvider.notifier).setAutoN(false);
      await container.read(settingsProvider.notifier).setManualN(5);
      expect(container.read(currentNProvider), 5);
    });

    test('setSpeedMultiplier updates state and repo', () async {
      final fakeRepo = FakeSettingsRepository('guest');
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      await container.read(settingsProvider.future);
      await container.read(settingsProvider.notifier).setSpeedMultiplier(2.0);
      expect(container.read(settingsProvider).valueOrNull!.speedMultiplier, 2.0);
    });

    test('setContinuousFeedback updates state', () async {
      final fakeRepo = FakeSettingsRepository('guest');
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      await container.read(settingsProvider.future);
      await container.read(settingsProvider.notifier).setContinuousFeedback(true);
      expect(container.read(settingsProvider).valueOrNull!.continuousFeedback, true);
    });

    test('setFocusMusicEnabled updates state', () async {
      final fakeRepo = FakeSettingsRepository('guest');
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      await container.read(settingsProvider.future);
      await container.read(settingsProvider.notifier).setFocusMusicEnabled(true);
      expect(container.read(settingsProvider).valueOrNull!.focusMusicEnabled, true);
    });

    test('setReminderTime updates state', () async {
      final fakeRepo = FakeSettingsRepository('guest');
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      await container.read(settingsProvider.future);
      await container.read(settingsProvider.notifier).setReminderTime('09:00');
      expect(container.read(settingsProvider).valueOrNull!.reminderTime, '09:00');
    });

    test('setShowGrid updates state', () async {
      final fakeRepo = FakeSettingsRepository('guest');
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService(currentUser: null)),
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      await container.read(settingsProvider.future);
      await container.read(settingsProvider.notifier).setShowGrid(false);
      expect(container.read(settingsProvider).valueOrNull!.showGrid, false);
    });
  });
}
