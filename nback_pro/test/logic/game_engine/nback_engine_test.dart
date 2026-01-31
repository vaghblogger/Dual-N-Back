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
  });
}
