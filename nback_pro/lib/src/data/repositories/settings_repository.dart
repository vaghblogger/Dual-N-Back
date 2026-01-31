import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_settings.dart';

const String _settingsBoxName = 'settings';
const String _settingsKey = 'user_settings';

class SettingsRepository {
  Box<UserSettings>? _box;

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
}
