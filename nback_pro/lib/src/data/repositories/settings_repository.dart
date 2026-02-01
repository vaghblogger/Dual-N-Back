import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_settings.dart';

const String _settingsKey = 'user_settings';

class SettingsRepository {
  SettingsRepository(this.userId);

  final String userId;

  Box<UserSettings>? _box;

  String get _settingsBoxName => 'settings_$userId';

  Future<Box<UserSettings>> _getBox() async {
    _box ??= await Hive.openBox<UserSettings>(_settingsBoxName);
    return _box!;
  }

  Future<UserSettings> getSettings() async {
    final box = await _getBox();
    final stored = box.get(_settingsKey);
    if (stored != null) return stored;
    final defaults = UserSettings();
    await saveSettings(defaults);
    return defaults;
  }

  Future<void> saveSettings(UserSettings settings) async {
    final box = await _getBox();
    await box.put(_settingsKey, settings);
  }

  /// Closes and deletes the settings box from disk. Use for full app reset.
  /// Callers must invalidate settings-related providers after this.
  Future<void> closeAndDeleteAll() async {
    if (_box != null) {
      await _box!.close();
      await Hive.deleteBoxFromDisk(_settingsBoxName);
      _box = null;
    }
  }
}
