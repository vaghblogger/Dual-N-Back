import 'package:flutter_test/flutter_test.dart';
import 'package:nback_pro/src/data/models/user_settings.dart';
import 'package:nback_pro/src/data/repositories/settings_repository.dart';
import '../../test_helpers.dart';

void main() {
  setUpAll(() async {
    await initHiveForTest();
  });

  tearDownAll(() async {
    await closeHiveForTest();
  });

  group('SettingsRepository', () {
    late SettingsRepository repo;

    setUp(() {
      repo = SettingsRepository(nextTestUserId);
    });

    tearDown(() async {
      await repo.closeAndDeleteAll();
    });

    test('getSettings empty returns defaults and saves them', () async {
      final settings = await repo.getSettings();
      expect(settings.selectedThemeId, 0);
      expect(settings.isAutoN, true);
      expect(settings.manualN, 1);
      expect(settings.speedMultiplier, 1.0);
      final again = await repo.getSettings();
      expect(again.selectedThemeId, settings.selectedThemeId);
    });

    test('saveSettings and getSettings round-trip', () async {
      final original = UserSettings(
        selectedThemeId: 3,
        isAutoN: false,
        manualN: 5,
        continuousFeedback: true,
        focusMusicEnabled: true,
        reminderTime: '08:30',
        speedMultiplier: 2.0,
        showGrid: false,
      );
      await repo.saveSettings(original);
      final loaded = await repo.getSettings();
      expect(loaded.selectedThemeId, 3);
      expect(loaded.isAutoN, false);
      expect(loaded.manualN, 5);
      expect(loaded.continuousFeedback, true);
      expect(loaded.focusMusicEnabled, true);
      expect(loaded.reminderTime, '08:30');
      expect(loaded.speedMultiplier, 2.0);
      expect(loaded.showGrid, false);
    });

    test('closeAndDeleteAll then getSettings returns fresh defaults', () async {
      await repo.saveSettings(UserSettings(selectedThemeId: 5));
      await repo.closeAndDeleteAll();
      final repo2 = SettingsRepository(repo.userId);
      final settings = await repo2.getSettings();
      expect(settings.selectedThemeId, 0);
      await repo2.closeAndDeleteAll();
    });
  });
}
