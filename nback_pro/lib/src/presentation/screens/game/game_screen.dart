import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/models/session_result.dart';
import '../../../data/services/audio_service.dart';
import '../../../logic/providers/game_provider.dart';
import '../../../logic/providers/settings_provider.dart';
import '../../../logic/providers/stats_provider.dart';

final audioServiceProvider = Provider<AudioService>((ref) => AudioService());

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Timer? _timer;
  bool _stimulusVisible = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    ref.read(audioServiceProvider).preloadAudio();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  void _runTrial() {
    final session = ref.read(gameSessionProvider);
    if (session == null || session.isComplete) return;
    if (_currentIndex >= session.trials.length) {
      _endSession();
      return;
    }

    final settings = ref.read(settingsProvider).valueOrNull;
    final speedMultiplier = settings?.speedMultiplier ?? 1.0;
    final trialDurationMs = (3000 / speedMultiplier).round();
    const stimulusMs = 500;

    final trial = session.trials[_currentIndex];
    ref.read(gameSessionProvider.notifier).setCurrentIndex(_currentIndex);

    setState(() => _stimulusVisible = true);
    _playLetter(trial.letter);

    _timer = Timer(const Duration(milliseconds: stimulusMs), () {
      if (!mounted) return;
      setState(() => _stimulusVisible = false);
      _timer = Timer(Duration(milliseconds: trialDurationMs - stimulusMs), () {
        if (!mounted) return;
        setState(() {
          _currentIndex++;
          ref.read(gameSessionProvider.notifier).setCurrentIndex(_currentIndex);
        });
        _runTrial();
      });
    });
  }

  Future<void> _playLetter(String letter) async {
    try {
      await ref.read(audioServiceProvider).playLetter(letter);
    } catch (e, st) {
      debugPrint('Audio playLetter failed for "$letter": $e');
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.audioUnavailable)),
        );
      }
    }
  }

  Future<void> _endSession() async {
    _timer?.cancel();
    final notifier = ref.read(gameSessionProvider.notifier);
    notifier.completeSession();
    final (audioScore, visualScore, totalAccuracy) = notifier.calculateScore();
    final session = ref.read(gameSessionProvider);
    if (session == null) return;
    final result = SessionResult(
      date: DateTime.now(),
      nLevel: session.nLevel,
      accuracy: totalAccuracy,
    );
    await persistSession(ref, result);
    ref.invalidate(allSessionsProvider);
    ref.invalidate(averageNProvider);
    ref.invalidate(daysTrainedInLast7DaysProvider);
    ref.invalidate(last7DaysCompletedProvider);
    ref.invalidate(currentStreakProvider);
    ref.invalidate(isChallengeCompleteTodayProvider);
    final newN = ref.read(currentNProvider);
    final settings = ref.read(settingsProvider).valueOrNull;
    final isAutoN = settings?.isAutoN ?? true;
    notifier.endSession();
    if (!mounted) return;
    ref.read(lastSessionSummaryProvider.notifier).state = SessionSummaryData(
      nLevel: session.nLevel,
      audioScore: audioScore,
      visualScore: visualScore,
      totalAccuracy: totalAccuracy,
      newN: newN,
      isAutoN: isAutoN,
    );
    if (!mounted) return;
    context.go('/session-summary');
  }

  void _pause() {
    _timer?.cancel();
    ref.read(gameSessionProvider.notifier).setPaused(true);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.pause),
        content: const Text('Resume or quit?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(gameSessionProvider.notifier).setPaused(false);
              _runTrial();
            },
            child: const Text(AppStrings.resume),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(gameSessionProvider.notifier).endSession();
              context.go('/home');
            },
            child: const Text(AppStrings.quit),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentIndex == 0 && !session.isComplete && _timer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(gameSessionProvider) != null) _runTrial();
      });
    }

    final trial = session.currentTrial;
    final activePosition = _stimulusVisible && trial != null ? trial.position : -1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${session.currentIndex + 1} / ${session.totalTrials}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: _pause,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: session.totalTrials > 0
                  ? (session.currentIndex + 1) / session.totalTrials
                  : 0,
            ),
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                            ),
                            itemCount: 9,
                            itemBuilder: (context, index) {
                              final isActive = index == activePosition;
                              return Container(
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).cardColor,
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                              );
                            },
                          ),
                          IgnorePointer(
                            child: Opacity(
                              opacity: 0.15,
                              child: Icon(
                                Icons.add,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => ref
                            .read(gameSessionProvider.notifier)
                            .submitResponse(true, false),
                        child: const Text(AppStrings.audioMatch),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => ref
                            .read(gameSessionProvider.notifier)
                            .submitResponse(false, true),
                        child: const Text(AppStrings.visualMatch),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
