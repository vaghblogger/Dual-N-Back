import 'package:flutter_test/flutter_test.dart';
import 'package:nback_pro/src/data/models/session_result.dart';

void main() {
  group('SessionResult', () {
    final sampleDate = DateTime(2025, 2, 7, 12, 0, 0);

    test('toMap and fromMap round-trip preserves data', () {
      final original = SessionResult(
        date: sampleDate,
        nLevel: 3,
        accuracy: 0.85,
        audioAccuracy: 0.9,
        visualAccuracy: 0.8,
      );
      final map = original.toMap();
      final restored = SessionResult.fromMap(map);
      expect(restored.date, sampleDate);
      expect(restored.nLevel, 3);
      expect(restored.accuracy, 0.85);
      expect(restored.audioAccuracy, 0.9);
      expect(restored.visualAccuracy, 0.8);
    });

    test('effectiveAudioAccuracy and effectiveVisualAccuracy return 0 when null', () {
      final result = SessionResult(
        date: sampleDate,
        nLevel: 2,
        accuracy: 0.7,
        audioAccuracy: null,
        visualAccuracy: null,
      );
      expect(result.effectiveAudioAccuracy, 0.0);
      expect(result.effectiveVisualAccuracy, 0.0);
    });

    test('effectiveAudioAccuracy and effectiveVisualAccuracy return value when set', () {
      final result = SessionResult(
        date: sampleDate,
        nLevel: 2,
        accuracy: 0.7,
        audioAccuracy: 0.8,
        visualAccuracy: 0.6,
      );
      expect(result.effectiveAudioAccuracy, 0.8);
      expect(result.effectiveVisualAccuracy, 0.6);
    });

    test('fromMap with empty map uses defaults', () {
      final result = SessionResult.fromMap({});
      expect(result.date, isNotNull);
      expect(result.nLevel, 1);
      expect(result.accuracy, 0.0);
      expect(result.audioAccuracy, isNull);
      expect(result.visualAccuracy, isNull);
    });

    test('fromMap with missing date uses DateTime.now', () {
      final result = SessionResult.fromMap({'nLevel': 2, 'accuracy': 0.5});
      expect(result.date, isNotNull);
      expect(result.nLevel, 2);
      expect(result.accuracy, 0.5);
    });

    test('fromMap with invalid date string falls back to DateTime.now', () {
      final result = SessionResult.fromMap({
        'date': 'not-a-date',
        'nLevel': 1,
        'accuracy': 0.0,
      });
      expect(result.date, isNotNull);
      expect(result.nLevel, 1);
    });

    test('fromMap with malformed nLevel/accuracy uses defaults', () {
      final result = SessionResult.fromMap({
        'date': sampleDate.toIso8601String(),
        'nLevel': null,
        'accuracy': null,
      });
      expect(result.nLevel, 1);
      expect(result.accuracy, 0.0);
    });
  });
}
