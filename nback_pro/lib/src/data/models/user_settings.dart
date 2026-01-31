import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 0)
class UserSettings extends HiveObject {
  @HiveField(0)
  int selectedThemeId;

  @HiveField(1)
  bool isAutoN;

  @HiveField(2)
  int manualN;

  @HiveField(3)
  bool continuousFeedback;

  @HiveField(4)
  bool focusMusicEnabled;

  @HiveField(5)
  String? reminderTime;

  @HiveField(6)
  double speedMultiplier;

  UserSettings({
    this.selectedThemeId = 0,
    this.isAutoN = true,
    this.manualN = 1,
    this.continuousFeedback = false,
    this.focusMusicEnabled = false,
    this.reminderTime,
    this.speedMultiplier = 1.0,
  });
}
