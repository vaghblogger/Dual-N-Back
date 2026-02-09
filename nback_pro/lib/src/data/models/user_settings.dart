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

  @HiveField(7)
  bool showGrid;

  @HiveField(8)
  bool tapSoundEnabled;

  /// When true: Position (Visual) left, Audio right. When false: Audio left, Position right.
  @HiveField(9)
  bool positionLeftAudioRight;

  UserSettings({
    this.selectedThemeId = 0,
    this.isAutoN = true,
    this.manualN = 1,
    this.continuousFeedback = false,
    this.focusMusicEnabled = false,
    this.reminderTime,
    this.speedMultiplier = 1.0,
    this.showGrid = false,
    this.tapSoundEnabled = false,
    this.positionLeftAudioRight = true,
  });

  /// For Firestore sync: serialize to map (DateTime as ISO string).
  Map<String, dynamic> toMap() {
    return {
      'selectedThemeId': selectedThemeId,
      'isAutoN': isAutoN,
      'manualN': manualN,
      'continuousFeedback': continuousFeedback,
      'focusMusicEnabled': focusMusicEnabled,
      'reminderTime': reminderTime,
      'speedMultiplier': speedMultiplier,
      'showGrid': showGrid,
      'tapSoundEnabled': tapSoundEnabled,
      'positionLeftAudioRight': positionLeftAudioRight,
    };
  }

  /// For Firestore sync: deserialize from map.
  static UserSettings fromMap(Map<String, dynamic>? map) {
    if (map == null) return UserSettings();
    return UserSettings(
      selectedThemeId: (map['selectedThemeId'] as num?)?.toInt() ?? 0,
      isAutoN: map['isAutoN'] as bool? ?? true,
      manualN: (map['manualN'] as num?)?.toInt() ?? 1,
      continuousFeedback: map['continuousFeedback'] as bool? ?? false,
      focusMusicEnabled: map['focusMusicEnabled'] as bool? ?? false,
      reminderTime: map['reminderTime'] as String?,
      speedMultiplier: (map['speedMultiplier'] as num?)?.toDouble() ?? 1.0,
      showGrid: map['showGrid'] as bool? ?? false,
      tapSoundEnabled: map['tapSoundEnabled'] as bool? ?? false,
      positionLeftAudioRight: map['positionLeftAudioRight'] as bool? ?? true,
    );
  }
}
