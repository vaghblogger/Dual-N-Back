import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nback_pro/src/logic/game_engine/nback_engine.dart';

void main() {
  group('NBackEngine', () {
    late NBackEngine engine;

    setUp(() {
      engine = NBackEngine();
    });

    test('generates correct number of trials', () {
      final trials = engine.generateSession(2, 22);
      expect(trials.length, 22);
    });

    test('match rate is approximately 30%', () {
      final trials = engine.generateSession(2, 100);
      final audioMatches = trials.where((t) => t.isAudioMatch).length;
      final visualMatches = trials.where((t) => t.isVisualMatch).length;

      expect(audioMatches, inInclusiveRange(20, 40));
      expect(visualMatches, inInclusiveRange(20, 40));
    });

    test('no matches occur before N trials', () {
      final trials = engine.generateSession(3, 23);

      expect(trials[0].isAudioMatch, false);
      expect(trials[0].isVisualMatch, false);
      expect(trials[1].isAudioMatch, false);
      expect(trials[1].isVisualMatch, false);
      expect(trials[2].isAudioMatch, false);
      expect(trials[2].isVisualMatch, false);
    });

    test('determinism with seeded Random', () {
      final engine1 = NBackEngine(Random(42));
      final engine2 = NBackEngine(Random(42));
      final trials1 = engine1.generateSession(2, 25);
      final trials2 = engine2.generateSession(2, 25);
      expect(trials1.length, trials2.length);
      for (var i = 0; i < trials1.length; i++) {
        expect(trials1[i].position, trials2[i].position);
        expect(trials1[i].letter, trials2[i].letter);
        expect(trials1[i].isAudioMatch, trials2[i].isAudioMatch);
        expect(trials1[i].isVisualMatch, trials2[i].isVisualMatch);
      }
    });

    test('edge case: totalTrials == n', () {
      final trials = engine.generateSession(3, 3);
      expect(trials.length, 3);
      for (final t in trials) {
        expect(t.isAudioMatch, false);
        expect(t.isVisualMatch, false);
      }
    });

    test('edge case: totalTrials == n + 1', () {
      final trials = engine.generateSession(2, 3);
      expect(trials.length, 3);
      expect(trials[0].isAudioMatch, false);
      expect(trials[0].isVisualMatch, false);
      expect(trials[1].isAudioMatch, false);
      expect(trials[1].isVisualMatch, false);
      // Index 2 is the only eligible slot; may or may not be match
    });

    test('edge case: n == 1', () {
      final trials = engine.generateSession(1, 21);
      expect(trials.length, 21);
      expect(trials[0].isAudioMatch, false);
      expect(trials[0].isVisualMatch, false);
    });

    test('edge case: n == 15', () {
      final trials = engine.generateSession(15, 35);
      expect(trials.length, 35);
      for (var i = 0; i < 15; i++) {
        expect(trials[i].isAudioMatch, false);
        expect(trials[i].isVisualMatch, false);
      }
    });

    test('stimulus correctness: audio match at i has same letter as i-n', () {
      final engineSeeded = NBackEngine(Random(123));
      final trials = engineSeeded.generateSession(3, 30);
      for (var i = 3; i < trials.length; i++) {
        if (trials[i].isAudioMatch) {
          expect(trials[i].letter, trials[i - 3].letter);
        }
      }
    });

    test('stimulus correctness: visual match at i has same position as i-n', () {
      final engineSeeded = NBackEngine(Random(456));
      final trials = engineSeeded.generateSession(2, 25);
      for (var i = 2; i < trials.length; i++) {
        if (trials[i].isVisualMatch) {
          expect(trials[i].position, trials[i - 2].position);
        }
      }
    });

    test('stimulus correctness: non-match audio differs from n-back letter', () {
      final engineSeeded = NBackEngine(Random(789));
      final trials = engineSeeded.generateSession(2, 24);
      for (var i = 2; i < trials.length; i++) {
        if (!trials[i].isAudioMatch) {
          expect(trials[i].letter, isNot(trials[i - 2].letter));
        }
      }
    });

    test('stimulus correctness: non-match visual differs from n-back position', () {
      final engineSeeded = NBackEngine(Random(101));
      final trials = engineSeeded.generateSession(2, 24);
      for (var i = 2; i < trials.length; i++) {
        if (!trials[i].isVisualMatch) {
          expect(trials[i].position, isNot(trials[i - 2].position));
        }
      }
    });

    test('generateSession(10, 200) completes within 100ms', () {
      final stopwatch = Stopwatch()..start();
      engine.generateSession(10, 200);
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('generateSession(15, 35) completes within 100ms', () {
      final stopwatch = Stopwatch()..start();
      engine.generateSession(15, 35);
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
