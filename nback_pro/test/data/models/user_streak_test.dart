import 'package:flutter_test/flutter_test.dart';
import 'package:nback_pro/src/data/models/user_streak.dart';

void main() {
  group('UserStreak', () {
    final sampleDate = DateTime(2025, 2, 7);

    test('toMap and fromMap round-trip preserves data', () {
      final original = UserStreak(
        currentStreak: 5,
        lastCompletedDate: sampleDate,
        longestStreak: 10,
      );
      final map = original.toMap();
      final restored = UserStreak.fromMap(map);
      expect(restored.currentStreak, 5);
      expect(restored.lastCompletedDate, sampleDate);
      expect(restored.longestStreak, 10);
    });

    test('fromMap(null) returns defaults', () {
      final result = UserStreak.fromMap(null);
      expect(result.currentStreak, 0);
      expect(result.lastCompletedDate, isNull);
      expect(result.longestStreak, 0);
    });

    test('fromMap with missing lastCompletedDate has null date', () {
      final result = UserStreak.fromMap({
        'currentStreak': 3,
        'longestStreak': 3,
      });
      expect(result.currentStreak, 3);
      expect(result.lastCompletedDate, isNull);
      expect(result.longestStreak, 3);
    });

    test('fromMap with invalid date string has null lastCompletedDate', () {
      final result = UserStreak.fromMap({
        'currentStreak': 1,
        'lastCompletedDate': 'invalid',
        'longestStreak': 1,
      });
      expect(result.lastCompletedDate, isNull);
    });

    test('toMap omits lastCompletedDate when null', () {
      final streak = UserStreak(
        currentStreak: 0,
        lastCompletedDate: null,
        longestStreak: 0,
      );
      final map = streak.toMap();
      expect(map['lastCompletedDate'], isNull);
      expect(map['currentStreak'], 0);
      expect(map['longestStreak'], 0);
    });
  });
}
