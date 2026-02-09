import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nback_pro/src/logic/game_engine/nback_engine.dart';
import 'package:nback_pro/src/logic/game_engine/trial.dart';
import 'package:nback_pro/src/logic/providers/game_provider.dart';
import 'package:nback_pro/src/logic/providers/subscription_provider.dart';

/// Fake engine that returns a fixed list of trials for predictable scoring tests.
class FakeNBackEngine extends NBackEngine {
  FakeNBackEngine(this.fixedTrials) : super(Random(0));

  final List<Trial> fixedTrials;

  @override
  List<Trial> generateSession(int n, int totalTrials) {
    return List<Trial>.from(fixedTrials.take(totalTrials));
  }
}

void main() {
  group('GameSessionNotifier', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    test('startSession with trialsPerSession override', () {
      final fixedTrials = List.generate(
        5,
        (i) => Trial(
          position: i % 9,
          letter: 'C',
          isVisualMatch: i >= 2 && i % 2 == 0,
          isAudioMatch: i >= 2 && i % 3 == 0,
        ),
      );
      container = ProviderContainer(
        overrides: [
          nBackEngineProvider.overrideWithValue(FakeNBackEngine(fixedTrials)),
        ],
      );
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(2, trialsPerSession: 5);
      final state = container.read(gameSessionProvider);
      expect(state, isNotNull);
      expect(state!.totalTrials, 5);
      expect(state.currentIndex, 0);
      expect(state.nLevel, 2);
      expect(state.isPaused, false);
      expect(state.isComplete, false);
    });

    test('startSession clamps totalTrials to at least n+1', () {
      final fixedTrials = List.generate(
        10,
        (i) => Trial(
          position: 0,
          letter: 'C',
          isVisualMatch: false,
          isAudioMatch: false,
        ),
      );
      container = ProviderContainer(
        overrides: [
          nBackEngineProvider.overrideWithValue(FakeNBackEngine(fixedTrials)),
        ],
      );
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(3, trialsPerSession: 2);
      final state = container.read(gameSessionProvider);
      expect(state!.totalTrials, 4);
    });

    test('submitResponse records at currentIndex', () {
      final fixedTrials = List.generate(
        3,
        (_) => const Trial(
          position: 0,
          letter: 'C',
          isVisualMatch: true,
          isAudioMatch: true,
        ),
      );
      container = ProviderContainer(
        overrides: [
          nBackEngineProvider.overrideWithValue(FakeNBackEngine(fixedTrials)),
        ],
      );
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(1, trialsPerSession: 3);
      notifier.submitResponse(true, false);
      var state = container.read(gameSessionProvider)!;
      expect(state.responses[0].audio, true);
      expect(state.responses[0].visual, false);
      notifier.setCurrentIndex(1);
      notifier.submitResponse(false, true);
      state = container.read(gameSessionProvider)!;
      expect(state.responses[1].audio, false);
      expect(state.responses[1].visual, true);
    });

    test('submitResponse with forIndex', () {
      final fixedTrials = List.generate(
        3,
        (_) => const Trial(
          position: 0,
          letter: 'C',
          isVisualMatch: true,
          isAudioMatch: true,
        ),
      );
      container = ProviderContainer(
        overrides: [
          nBackEngineProvider.overrideWithValue(FakeNBackEngine(fixedTrials)),
        ],
      );
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(1, trialsPerSession: 3);
      notifier.submitResponse(true, true, forIndex: 2);
      final state = container.read(gameSessionProvider)!;
      expect(state.responses[2].audio, true);
      expect(state.responses[2].visual, true);
    });

    test('submitResponse when state is null does nothing', () {
      container = ProviderContainer();
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.submitResponse(true, true);
      expect(container.read(gameSessionProvider), isNull);
    });

    test('submitResponse out of range does nothing', () {
      final fixedTrials = List.generate(
        3,
        (_) => const Trial(
          position: 0,
          letter: 'C',
          isVisualMatch: false,
          isAudioMatch: false,
        ),
      );
      container = ProviderContainer(
        overrides: [
          nBackEngineProvider.overrideWithValue(FakeNBackEngine(fixedTrials)),
        ],
      );
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(1, trialsPerSession: 3);
      notifier.submitResponse(true, true, forIndex: 10);
      final state = container.read(gameSessionProvider)!;
      expect(state.responses.every((r) => !r.audio && !r.visual), true);
    });

    test('calculateScore all correct', () {
      final fixedTrials = [
        const Trial(position: 0, letter: 'C', isVisualMatch: false, isAudioMatch: false),
        const Trial(position: 1, letter: 'H', isVisualMatch: false, isAudioMatch: false),
        const Trial(position: 2, letter: 'K', isVisualMatch: true, isAudioMatch: true),
      ];
      container = ProviderContainer(
        overrides: [
          nBackEngineProvider.overrideWithValue(FakeNBackEngine(fixedTrials)),
        ],
      );
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(1, trialsPerSession: 3);
      notifier.submitResponse(true, true, forIndex: 2);
      final (audio, visual, total) = notifier.calculateScore();
      expect(audio, 1.0);
      expect(visual, 1.0);
      expect(total, 1.0);
    });

    test('calculateScore all wrong (no taps on matches)', () {
      final fixedTrials = [
        const Trial(position: 0, letter: 'C', isVisualMatch: false, isAudioMatch: false),
        const Trial(position: 1, letter: 'H', isVisualMatch: true, isAudioMatch: true),
      ];
      container = ProviderContainer(
        overrides: [
          nBackEngineProvider.overrideWithValue(FakeNBackEngine(fixedTrials)),
        ],
      );
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(1, trialsPerSession: 2);
      final (audio, visual, total) = notifier.calculateScore();
      expect(audio, 0.0);
      expect(visual, 0.0);
      expect(total, 0.0);
    });

    test('calculateScore partial and totalAccuracy is average of channels', () {
      final fixedTrials = [
        const Trial(position: 0, letter: 'C', isVisualMatch: false, isAudioMatch: false),
        const Trial(position: 1, letter: 'H', isVisualMatch: true, isAudioMatch: true),
        const Trial(position: 2, letter: 'K', isVisualMatch: true, isAudioMatch: true),
      ];
      container = ProviderContainer(
        overrides: [
          nBackEngineProvider.overrideWithValue(FakeNBackEngine(fixedTrials)),
        ],
      );
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(1, trialsPerSession: 3);
      notifier.submitResponse(true, false, forIndex: 1);
      notifier.submitResponse(false, true, forIndex: 2);
      final (audio, visual, total) = notifier.calculateScore();
      expect(audio, 0.5);
      expect(visual, 0.5);
      expect(total, 0.5);
    });

    test('calculateScore no matches returns 0', () {
      final fixedTrials = List.generate(
        3,
        (_) => const Trial(
          position: 0,
          letter: 'C',
          isVisualMatch: false,
          isAudioMatch: false,
        ),
      );
      container = ProviderContainer(
        overrides: [
          nBackEngineProvider.overrideWithValue(FakeNBackEngine(fixedTrials)),
        ],
      );
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(1, trialsPerSession: 3);
      final (audio, visual, total) = notifier.calculateScore();
      expect(audio, 0.0);
      expect(visual, 0.0);
      expect(total, 0.0);
    });

    test('calculateScore when state null returns zeros', () {
      container = ProviderContainer();
      final notifier = container.read(gameSessionProvider.notifier);
      final (a, v, t) = notifier.calculateScore();
      expect(a, 0.0);
      expect(v, 0.0);
      expect(t, 0.0);
    });

    test('adjustNLevel when isAutoNEnabled false returns current N', () {
      container = ProviderContainer(
        overrides: [isPremiumProvider.overrideWithValue(true)],
      );
      container.read(currentNProvider.notifier).state = 5;
      final notifier = container.read(gameSessionProvider.notifier);
      final result = notifier.adjustNLevel(0.9, false);
      expect(result, 5);
    });

    test('adjustNLevel >= 70% moves up, premium cap 15', () {
      container = ProviderContainer(
        overrides: [isPremiumProvider.overrideWithValue(true)],
      );
      container.read(currentNProvider.notifier).state = 14;
      final notifier = container.read(gameSessionProvider.notifier);
      final result = notifier.adjustNLevel(0.70, true);
      expect(result, 15);
      expect(container.read(currentNProvider), 15);
    });

    test('adjustNLevel < 70% moves down', () {
      container = ProviderContainer(
        overrides: [isPremiumProvider.overrideWithValue(true)],
      );
      container.read(currentNProvider.notifier).state = 3;
      final notifier = container.read(gameSessionProvider.notifier);
      final result = notifier.adjustNLevel(0.69, true);
      expect(result, 2);
      expect(container.read(currentNProvider), 2);
    });

    test('adjustNLevel free user cap 3', () {
      container = ProviderContainer(
        overrides: [isPremiumProvider.overrideWithValue(false)],
      );
      container.read(currentNProvider.notifier).state = 3;
      final notifier = container.read(gameSessionProvider.notifier);
      final result = notifier.adjustNLevel(0.99, true);
      expect(result, 3);
      expect(container.read(currentNProvider), 3);
    });

    test('setPaused toggles isPaused', () {
      container = ProviderContainer(
        overrides: [
          nBackEngineProvider.overrideWithValue(NBackEngine()),
        ],
      );
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(1, trialsPerSession: 3);
      expect(container.read(gameSessionProvider)!.isPaused, false);
      notifier.setPaused(true);
      expect(container.read(gameSessionProvider)!.isPaused, true);
      notifier.setPaused(false);
      expect(container.read(gameSessionProvider)!.isPaused, false);
    });

    test('completeSession sets isComplete', () {
      container = ProviderContainer(
        overrides: [
          nBackEngineProvider.overrideWithValue(NBackEngine()),
        ],
      );
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(1, trialsPerSession: 3);
      expect(container.read(gameSessionProvider)!.isComplete, false);
      notifier.completeSession();
      expect(container.read(gameSessionProvider)!.isComplete, true);
    });

    test('endSession clears state', () {
      container = ProviderContainer(
        overrides: [
          nBackEngineProvider.overrideWithValue(NBackEngine()),
        ],
      );
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.startSession(1, trialsPerSession: 3);
      expect(container.read(gameSessionProvider), isNotNull);
      notifier.endSession();
      expect(container.read(gameSessionProvider), isNull);
    });
  });
}
