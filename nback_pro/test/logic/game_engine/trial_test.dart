import 'package:flutter_test/flutter_test.dart';
import 'package:nback_pro/src/logic/game_engine/trial.dart';

void main() {
  group('Trial', () {
    test('const constructor stores all fields', () {
      const t = Trial(
        position: 4,
        letter: 'C',
        isVisualMatch: true,
        isAudioMatch: false,
      );
      expect(t.position, 4);
      expect(t.letter, 'C');
      expect(t.isVisualMatch, true);
      expect(t.isAudioMatch, false);
    });

    test('two trials with same fields are equal', () {
      const t1 = Trial(
        position: 0,
        letter: 'H',
        isVisualMatch: false,
        isAudioMatch: true,
      );
      const t2 = Trial(
        position: 0,
        letter: 'H',
        isVisualMatch: false,
        isAudioMatch: true,
      );
      expect(t1.position, t2.position);
      expect(t1.letter, t2.letter);
      expect(t1.isVisualMatch, t2.isVisualMatch);
      expect(t1.isAudioMatch, t2.isAudioMatch);
    });
  });
}
