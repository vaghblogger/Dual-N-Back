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

  /// Audio channel accuracy 0.0–1.0. Null for sessions saved before this field existed.
  @HiveField(3)
  double? audioAccuracy;

  /// Visual channel accuracy 0.0–1.0. Null for sessions saved before this field existed.
  @HiveField(4)
  double? visualAccuracy;

  SessionResult({
    required this.date,
    required this.nLevel,
    required this.accuracy,
    this.audioAccuracy,
    this.visualAccuracy,
  });

  /// Effective audio accuracy for display (0.0 when not stored).
  double get effectiveAudioAccuracy => audioAccuracy ?? 0.0;

  /// Effective visual accuracy for display (0.0 when not stored).
  double get effectiveVisualAccuracy => visualAccuracy ?? 0.0;

  /// For Firestore sync: serialize to map (date as ISO string).
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'nLevel': nLevel,
      'accuracy': accuracy,
      if (audioAccuracy != null) 'audioAccuracy': audioAccuracy,
      if (visualAccuracy != null) 'visualAccuracy': visualAccuracy,
    };
  }

  /// For Firestore sync: deserialize from map.
  static SessionResult fromMap(Map<String, dynamic> map) {
    final dateStr = map['date'] as String?;
    return SessionResult(
      date: dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now(),
      nLevel: (map['nLevel'] as num?)?.toInt() ?? 1,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      audioAccuracy: (map['audioAccuracy'] as num?)?.toDouble(),
      visualAccuracy: (map['visualAccuracy'] as num?)?.toDouble(),
    );
  }
}
