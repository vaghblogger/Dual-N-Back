import 'package:flutter_test/flutter_test.dart';
import 'package:nback_pro/src/data/models/user_settings.dart';

void main() {
  group('UserSettings', () {
    test('toMap and fromMap round-trip preserves data', () {
      final original = UserSettings(
        selectedThemeId: 2,
        isAutoN: false,
        manualN: 4,
        continuousFeedback: true,
        focusMusicEnabled: true,
        reminderTime: '09:00',
        speedMultiplier: 1.5,
        showGrid: false,
      );
      final map = original.toMap();
      final restored = UserSettings.fromMap(map);
      expect(restored.selectedThemeId, 2);
      expect(restored.isAutoN, false);
      expect(restored.manualN, 4);
      expect(restored.continuousFeedback, true);
      expect(restored.focusMusicEnabled, true);
      expect(restored.reminderTime, '09:00');
      expect(restored.speedMultiplier, 1.5);
      expect(restored.showGrid, false);
    });

    test('fromMap(null) returns defaults', () {
      final result = UserSettings.fromMap(null);
      expect(result.selectedThemeId, 0);
      expect(result.isAutoN, true);
      expect(result.manualN, 1);
      expect(result.continuousFeedback, false);
      expect(result.focusMusicEnabled, false);
      expect(result.reminderTime, isNull);
      expect(result.speedMultiplier, 1.0);
      expect(result.showGrid, true);
    });

    test('fromMap with empty map uses defaults', () {
      final result = UserSettings.fromMap({});
      expect(result.selectedThemeId, 0);
      expect(result.isAutoN, true);
      expect(result.manualN, 1);
      expect(result.continuousFeedback, false);
      expect(result.focusMusicEnabled, false);
      expect(result.reminderTime, isNull);
      expect(result.speedMultiplier, 1.0);
      expect(result.showGrid, true);
    });

    test('fromMap with partial map fills rest with defaults', () {
      final result = UserSettings.fromMap({
        'selectedThemeId': 5,
        'isAutoN': false,
      });
      expect(result.selectedThemeId, 5);
      expect(result.isAutoN, false);
      expect(result.manualN, 1);
      expect(result.speedMultiplier, 1.0);
    });
  });
}
