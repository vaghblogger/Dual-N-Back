import 'package:hive/hive.dart';

part 'user_streak.g.dart';

@HiveType(typeId: 2)
class UserStreak extends HiveObject {
  @HiveField(0)
  int currentStreak;

  @HiveField(1)
  DateTime? lastCompletedDate;

  UserStreak({
    this.currentStreak = 0,
    this.lastCompletedDate,
  });
}
