import 'dart:math';

import 'trial.dart';

class NBackEngine {
  final Random _random = Random();
  static const List<String> _letters = ['C', 'H', 'K', 'L', 'Q', 'R', 'S', 'T'];

  /// Generates a session with [totalTrials] (typically 20 + n).
  /// Target: ~30% of trials are matches (audio and visual independently).
  List<Trial> generateSession(int n, int totalTrials) {
    final eligibleCount = totalTrials - n;
    if (eligibleCount <= 0) {
      return List.generate(
        totalTrials,
        (_) => Trial(
          position: _random.nextInt(9),
          letter: _letters[_random.nextInt(_letters.length)],
          isVisualMatch: false,
          isAudioMatch: false,
        ),
      );
    }

    final targetMatchesPerChannel = (totalTrials * 0.3).round();
    final audioMatchCount = targetMatchesPerChannel.clamp(0, eligibleCount);
    final visualMatchCount = targetMatchesPerChannel.clamp(0, eligibleCount);
    final eligibleIndices = List.generate(eligibleCount, (i) => n + i);

    final audioShuffle = List<int>.from(eligibleIndices)..shuffle(_random);
    final audioMatchIndices = audioShuffle.take(audioMatchCount).toSet();

    final visualShuffle = List<int>.from(eligibleIndices)..shuffle(_random);
    final visualMatchIndices = visualShuffle.take(visualMatchCount).toSet();

    final trials = <Trial>[];

    for (int i = 0; i < totalTrials; i++) {
      final shouldAudioMatch = audioMatchIndices.contains(i);
      final shouldVisualMatch = visualMatchIndices.contains(i);

      String letter;
      int position;

      if (shouldAudioMatch && i >= n) {
        letter = trials[i - n].letter;
      } else {
        letter = _letters[_random.nextInt(_letters.length)];
      }

      if (shouldVisualMatch && i >= n) {
        position = trials[i - n].position;
      } else {
        position = _random.nextInt(9);
      }

      trials.add(Trial(
        position: position,
        letter: letter,
        isVisualMatch: shouldVisualMatch,
        isAudioMatch: shouldAudioMatch,
      ));
    }

    return trials;
  }
}
