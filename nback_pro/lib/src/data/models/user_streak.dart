import 'package:hive/hive.dart';

part 'user_streak.g.dart';

@HiveType(typeId: 2)
class UserStreak extends HiveObject {
  @HiveField(0)
  int currentStreak;

  @HiveField(1)
  DateTime? lastCompletedDate;

  @HiveField(2)
  int longestStreak;

  UserStreak({
    this.currentStreak = 0,
    this.lastCompletedDate,
    this.longestStreak = 0,
  });

  /// For Firestore sync: serialize to map (DateTime as ISO string).
  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'longestStreak': longestStreak,
    };
  }

  /// For Firestore sync: deserialize from map.
  static UserStreak fromMap(Map<String, dynamic>? map) {
    if (map == null) return UserStreak();
    final dateStr = map['lastCompletedDate'] as String?;
    return UserStreak(
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      lastCompletedDate: dateStr != null ? DateTime.tryParse(dateStr) : null,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
    );
  }
}
