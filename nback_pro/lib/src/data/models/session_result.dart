import 'package:hive/hive.dart';

part 'session_result.g.dart';

@HiveType(typeId: 1)
class SessionResult extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  int nLevel;

  @HiveField(2)
  double accuracy;

  SessionResult({
    required this.date,
    required this.nLevel,
    required this.accuracy,
  });
}
