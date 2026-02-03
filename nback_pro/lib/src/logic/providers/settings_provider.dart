import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/settings_constants.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/sync_service.dart';
import 'auth_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final userId = ref.watch(currentStorageUserIdProvider);
  return SettingsRepository(userId);
});

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, UserSettings>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = await repo.getSettings();
    // Snap speed to nearest of the seven options when loading.
    final current = settings.speedMultiplier;
    int best = 0;
    for (int i = 0; i < speedOptions.length; i++) {
      if ((speedOptions[i] - current).abs() < (speedOptions[best] - current).abs()) {
        best = i;
      }
    }
    final snapped = speedOptions[best];
    if ((snapped - current).abs() > 0.01) {
      final updated = UserSettings(
        selectedThemeId: settings.selectedThemeId,
        isAutoN: settings.isAutoN,
        manualN: settings.manualN,
        continuousFeedback: settings.continuousFeedback,
        focusMusicEnabled: settings.focusMusicEnabled,
        reminderTime: settings.reminderTime,
        speedMultiplier: snapped,
        showGrid: settings.showGrid,
      );
      await repo.saveSettings(updated);
      return updated;
    }
    return settings;
  }

  Future<void> updateTheme(int themeId) async {
    final settings = state.value;
    if (settings == null) return;
    final updated = UserSettings(
      selectedThemeId: themeId,
      isAutoN: settings.isAutoN,
      manualN: settings.manualN,
      continuousFeedback: settings.continuousFeedback,
      focusMusicEnabled: settings.focusMusicEnabled,
      reminderTime: settings.reminderTime,
      speedMultiplier: settings.speedMultiplier,
      showGrid: settings.showGrid,
    );
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    await _pushSettingsIfSignedIn(updated);
    state = AsyncData(updated);
  }

  Future<void> saveSettings(UserSettings settings) async {
    await ref.read(settingsRepositoryProvider).saveSettings(settings);
    await _pushSettingsIfSignedIn(settings);
    state = AsyncData(settings);
  }

  Future<void> _pushSettingsIfSignedIn(UserSettings settings) async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await SyncService().pushSettings(user.uid, settings);
    }
  }

  Future<void> setAutoN(bool value) async {
    final settings = state.value;
    if (settings == null) return;
    final updated = UserSettings(
      selectedThemeId: settings.selectedThemeId,
      isAutoN: value,
      manualN: settings.manualN,
      continuousFeedback: settings.continuousFeedback,
      focusMusicEnabled: settings.focusMusicEnabled,
      reminderTime: settings.reminderTime,
      speedMultiplier: settings.speedMultiplier,
      showGrid: settings.showGrid,
    );
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    await _pushSettingsIfSignedIn(updated);
    state = AsyncData(updated);
  }

  Future<void> toggleAutoN() async {
    final settings = state.value;
    if (settings == null) return;
    final updated = UserSettings(
      selectedThemeId: settings.selectedThemeId,
      isAutoN: !settings.isAutoN,
      manualN: settings.manualN,
      continuousFeedback: settings.continuousFeedback,
      focusMusicEnabled: settings.focusMusicEnabled,
      reminderTime: settings.reminderTime,
      speedMultiplier: settings.speedMultiplier,
      showGrid: settings.showGrid,
    );
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    await _pushSettingsIfSignedIn(updated);
    state = AsyncData(updated);
  }

  Future<void> setManualN(int n) async {
    final settings = state.value;
    if (settings == null) return;
    final updated = UserSettings(
      selectedThemeId: settings.selectedThemeId,
      isAutoN: settings.isAutoN,
      manualN: n.clamp(1, 15),
      continuousFeedback: settings.continuousFeedback,
      focusMusicEnabled: settings.focusMusicEnabled,
      reminderTime: settings.reminderTime,
      speedMultiplier: settings.speedMultiplier,
      showGrid: settings.showGrid,
    );
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    await _pushSettingsIfSignedIn(updated);
    state = AsyncData(updated);
  }

  Future<void> setSpeedMultiplier(double multiplier) async {
    final settings = state.value;
    if (settings == null) return;
    final updated = UserSettings(
      selectedThemeId: settings.selectedThemeId,
      isAutoN: settings.isAutoN,
      manualN: settings.manualN,
      continuousFeedback: settings.continuousFeedback,
      focusMusicEnabled: settings.focusMusicEnabled,
      reminderTime: settings.reminderTime,
      speedMultiplier: multiplier,
      showGrid: settings.showGrid,
    );
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    await _pushSettingsIfSignedIn(updated);
    state = AsyncData(updated);
  }

  Future<void> setContinuousFeedback(bool value) async {
    final settings = state.value;
    if (settings == null) return;
    final updated = UserSettings(
      selectedThemeId: settings.selectedThemeId,
      isAutoN: settings.isAutoN,
      manualN: settings.manualN,
      continuousFeedback: value,
      focusMusicEnabled: settings.focusMusicEnabled,
      reminderTime: settings.reminderTime,
      speedMultiplier: settings.speedMultiplier,
      showGrid: settings.showGrid,
    );
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    await _pushSettingsIfSignedIn(updated);
    state = AsyncData(updated);
  }

  Future<void> setFocusMusicEnabled(bool value) async {
    final settings = state.value;
    if (settings == null) return;
    final updated = UserSettings(
      selectedThemeId: settings.selectedThemeId,
      isAutoN: settings.isAutoN,
      manualN: settings.manualN,
      continuousFeedback: settings.continuousFeedback,
      focusMusicEnabled: value,
      reminderTime: settings.reminderTime,
      speedMultiplier: settings.speedMultiplier,
      showGrid: settings.showGrid,
    );
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    await _pushSettingsIfSignedIn(updated);
    state = AsyncData(updated);
  }

  Future<void> setReminderTime(String? isoTime) async {
    final settings = state.value;
    if (settings == null) return;
    final updated = UserSettings(
      selectedThemeId: settings.selectedThemeId,
      isAutoN: settings.isAutoN,
      manualN: settings.manualN,
      continuousFeedback: settings.continuousFeedback,
      focusMusicEnabled: settings.focusMusicEnabled,
      reminderTime: isoTime,
      speedMultiplier: settings.speedMultiplier,
      showGrid: settings.showGrid,
    );
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    await _pushSettingsIfSignedIn(updated);
    state = AsyncData(updated);
  }

  Future<void> setShowGrid(bool value) async {
    final settings = state.value;
    if (settings == null) return;
    final updated = UserSettings(
      selectedThemeId: settings.selectedThemeId,
      isAutoN: settings.isAutoN,
      manualN: settings.manualN,
      continuousFeedback: settings.continuousFeedback,
      focusMusicEnabled: settings.focusMusicEnabled,
      reminderTime: settings.reminderTime,
      speedMultiplier: settings.speedMultiplier,
      showGrid: value,
    );
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    await _pushSettingsIfSignedIn(updated);
    state = AsyncData(updated);
  }
}
