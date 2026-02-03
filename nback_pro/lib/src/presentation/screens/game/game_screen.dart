import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/models/session_result.dart';
import '../../../data/models/user_settings.dart';
import '../../../debug/simulator_runner.dart';
import '../../../data/services/audio_service.dart';
import '../../../logic/providers/audio_service_provider.dart';
import '../../../logic/providers/game_provider.dart';
import '../../../logic/providers/settings_provider.dart';
import '../../../logic/providers/stats_provider.dart';
import '../../../logic/providers/subscription_provider.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Timer? _timer;
  Timer? _autoPlayTimer;
  Timer? _feedbackAudioTimer;
  Timer? _feedbackVisualTimer;
  Timer? _initialHoldTimer;
  bool _initialHoldScheduled = false;
  bool _stimulusVisible = false;
  int _currentIndex = 0;
  Stopwatch? _runStopwatch;
  bool? _feedbackAudio;
  bool? _feedbackVisual;
  AudioService? _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(audioServiceProvider);
    WakelockPlus.enable();
    _audioService?.preloadAudio();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final skipFocus = ref.read(skipFocusMusicThisSessionProvider);
      if (skipFocus) {
        ref.read(skipFocusMusicThisSessionProvider.notifier).state = false;
      }
      ref.read(settingsProvider.future).then((settings) {
        if (!mounted) return;
        if (skipFocus) return; // Pre-game already had focus music; do not start again.
        if (settings.focusMusicEnabled) {
          _audioService?.startFocusMusic();
        }
      }).catchError((_) {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoPlayTimer?.cancel();
    _feedbackAudioTimer?.cancel();
    _feedbackVisualTimer?.cancel();
    _initialHoldTimer?.cancel();
    _audioService?.stopFocusMusic();
    WakelockPlus.disable();
    super.dispose();
  }

  void _onResponse(bool audio, bool visual) {
    final session = ref.read(gameSessionProvider);
    if (session == null || session.isComplete) return;
    final trial = session.currentTrial;
    if (trial == null) return;
    // Do not cancel _timer or advance: pace of visual/audio is fixed by the timer in _runTrial.
    ref.read(gameSessionProvider.notifier).submitResponse(audio, visual);
    final settings = ref.read(settingsProvider).valueOrNull;
    final continuousFeedback = settings?.continuousFeedback ?? false;
    if (continuousFeedback) {
      final sessionAfter = ref.read(gameSessionProvider);
      final resp = sessionAfter != null && session.currentIndex < sessionAfter.responses.length
          ? sessionAfter.responses[session.currentIndex]
          : (audio: audio, visual: visual);
      setState(() {
        // Only set feedback for the button that was just pressed.
        if (audio) {
          _feedbackAudio = resp.audio == trial.isAudioMatch;
          _feedbackAudioTimer?.cancel();
          _feedbackAudioTimer = Timer(const Duration(milliseconds: 600), () {
            if (!mounted) return;
            _feedbackAudioTimer = null;
            setState(() => _feedbackAudio = null);
          });
        }
        if (visual) {
          _feedbackVisual = resp.visual == trial.isVisualMatch;
          _feedbackVisualTimer?.cancel();
          _feedbackVisualTimer = Timer(const Duration(milliseconds: 600), () {
            if (!mounted) return;
            _feedbackVisualTimer = null;
            setState(() => _feedbackVisual = null);
          });
        }
      });
    }
  }

  void _runTrial() {
    final session = ref.read(gameSessionProvider);
    if (session == null || session.isComplete) return;
    if (_currentIndex >= session.trials.length) {
      _endSession();
      return;
    }

    // Clear any feedback from the previous trial so it doesn't carry over.
    _feedbackAudioTimer?.cancel();
    _feedbackAudioTimer = null;
    _feedbackVisualTimer?.cancel();
    _feedbackVisualTimer = null;
    setState(() {
      _feedbackAudio = null;
      _feedbackVisual = null;
    });

    final simulatorState = ref.read(simulatorRunnerProvider);
    if (_currentIndex == 0 && simulatorState.isActive && _runStopwatch == null) {
      _runStopwatch = Stopwatch()..start();
    }

    final overrides = ref.read(sessionOverridesProvider);
    final settings = ref.read(settingsProvider).valueOrNull;
    final speedMultiplier = overrides?.speedMultiplier ?? settings?.speedMultiplier ?? 1.0;
    final trialDurationMs = (3000 / speedMultiplier).round();
    const stimulusMs = 500;

    final trial = session.trials[_currentIndex];
    ref.read(gameSessionProvider.notifier).setCurrentIndex(_currentIndex);

    setState(() => _stimulusVisible = true);
    _playLetter(trial.letter);

    if (simulatorState.isActive) {
      _autoPlayTimer?.cancel();
      _autoPlayTimer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        ref.read(gameSessionProvider.notifier).submitResponse(
              trial.isAudioMatch,
              trial.isVisualMatch,
            );
      });
    }

    _timer = Timer(const Duration(milliseconds: stimulusMs), () {
      if (!mounted) return;
      setState(() => _stimulusVisible = false);
      _timer = Timer(Duration(milliseconds: trialDurationMs - stimulusMs), () {
        if (!mounted) return;
        _currentIndex++;
        // Only update notifier while still in range so UI never shows e.g. 22/21
        final sessionNow = ref.read(gameSessionProvider);
        if (sessionNow != null && _currentIndex < sessionNow.trials.length) {
          ref.read(gameSessionProvider.notifier).setCurrentIndex(_currentIndex);
        }
        setState(() {});
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
    _autoPlayTimer?.cancel();
    ref.read(audioServiceProvider).stopFocusMusic();
    final notifier = ref.read(gameSessionProvider.notifier);
    notifier.completeSession();
    final (audioScore, visualScore, totalAccuracy) = notifier.calculateScore();
    final session = ref.read(gameSessionProvider);
    if (session == null) return;

    final runner = ref.read(simulatorRunnerProvider.notifier);
    final runnerState = ref.read(simulatorRunnerProvider);

    if (runnerState.isActive) {
      _runStopwatch?.stop();
      final durationMs = _runStopwatch?.elapsedMilliseconds ?? 0;
      _runStopwatch = null;
      final newN = ref.read(currentNProvider);
      final settings = ref.read(settingsProvider).valueOrNull;
      final isPremium = ref.read(isPremiumProvider);
      final isAutoN = isPremium ? true : (settings?.isAutoN ?? true);
      final result = SessionResult(
        date: DateTime.now(),
        nLevel: session.nLevel,
        accuracy: totalAccuracy,
        audioAccuracy: audioScore,
        visualAccuracy: visualScore,
      );
      await persistSession(ref, result);
      ref.invalidate(allSessionsProvider);
      ref.invalidate(sessionsCompletedTodayProvider);
      ref.invalidate(averageNProvider);
      ref.invalidate(highestNProvider);
      ref.invalidate(daysTrainedInLast7DaysProvider);
      ref.invalidate(last7DaysCompletedProvider);
      ref.invalidate(currentStreakProvider);
      ref.invalidate(isChallengeCompleteTodayProvider);
      notifier.endSession();
      ref.read(sessionOverridesProvider.notifier).state = null;

      final entry = SimulatorLogEntry(
        runId: runnerState.logs.length + 1,
        mode: isAutoN ? 'AutoN' : 'MyN',
        nLevel: session.nLevel,
        nLevelAfter: isAutoN ? newN : null,
        speed: settings?.speedMultiplier ?? 1.0,
        totalTrials: session.totalTrials,
        durationMs: durationMs,
        audioScore: audioScore,
        visualScore: visualScore,
        totalAccuracy: totalAccuracy,
        timestamp: DateTime.now().toIso8601String(),
      );
      final next = await runner.recordRunAndPrepareNext(entry);
      if (!mounted) return;
      if (next != null) {
        final currentSettings = ref.read(settingsProvider).valueOrNull;
        if (currentSettings != null) {
          final updated = UserSettings(
            selectedThemeId: currentSettings.selectedThemeId,
            isAutoN: next.isAutoN,
            manualN: next.n.clamp(1, 15),
            continuousFeedback: currentSettings.continuousFeedback,
            focusMusicEnabled: currentSettings.focusMusicEnabled,
            reminderTime: currentSettings.reminderTime,
            speedMultiplier: next.speed,
          );
          await ref.read(settingsProvider.notifier).saveSettings(updated);
        }
        ref.read(currentNProvider.notifier).state = next.n;
        final runnerState = ref.read(simulatorRunnerProvider);
        ref.read(gameSessionProvider.notifier).startSession(
              next.n,
              trialsPerSession: runnerState.trialsPerSession,
            );
        ref.read(lastSessionSummaryProvider.notifier).state = null;
        if (!mounted) return;
        setState(() {
          _currentIndex = 0;
          _stimulusVisible = false;
        });
        _runStopwatch = Stopwatch()..start();
        _runTrial();
        return;
      }
      ref.read(lastSessionSummaryProvider.notifier).state = SessionSummaryData(
        nLevel: session.nLevel,
        audioScore: audioScore,
        visualScore: visualScore,
        totalAccuracy: totalAccuracy,
        newN: newN,
        isAutoN: isAutoN,
      );
      if (!mounted) return;
      context.go('/simulator-summary');
      return;
    }

    final result = SessionResult(
      date: DateTime.now(),
      nLevel: session.nLevel,
      accuracy: totalAccuracy,
      audioAccuracy: audioScore,
      visualAccuracy: visualScore,
    );
    await persistSession(ref, result);
    ref.invalidate(allSessionsProvider);
    ref.invalidate(sessionsCompletedTodayProvider);
    ref.invalidate(averageNProvider);
    ref.invalidate(highestNProvider);
    ref.invalidate(daysTrainedInLast7DaysProvider);
    ref.invalidate(last7DaysCompletedProvider);
    ref.invalidate(currentStreakProvider);
    ref.invalidate(isChallengeCompleteTodayProvider);
    final newN = ref.read(currentNProvider);
    final settings = ref.read(settingsProvider).valueOrNull;
    final isPremium = ref.read(isPremiumProvider);
    final isAutoN = isPremium ? true : (settings?.isAutoN ?? true);
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
    ref.read(sessionOverridesProvider.notifier).state = null;
    // Navigate immediately so summary is shown (session is left non-null so
    // game screen does not redirect to home).
    context.go('/session-summary');
  }

  void _pause() {
    _timer?.cancel();
    _autoPlayTimer?.cancel();
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
              ref.read(sessionOverridesProvider.notifier).state = null;
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
      // Don't navigate away if simulator is active and we're about to start the next run.
      if (!ref.read(simulatorRunnerProvider).isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/home');
        });
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Before first pattern: show training grid for 2 seconds, then start.
    if (_currentIndex == 0 && !session.isComplete && _timer == null && !_initialHoldScheduled) {
      _initialHoldScheduled = true;
      _initialHoldTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        _initialHoldTimer?.cancel();
        _initialHoldTimer = null;
        if (ref.read(gameSessionProvider) != null) _runTrial();
      });
    }

    final trial = session.currentTrial;
    final activePosition = _stimulusVisible && trial != null ? trial.position : -1;

    final simulatorActive = ref.watch(simulatorRunnerProvider).isActive;
    final overrides = ref.watch(sessionOverridesProvider);
    final showGrid = overrides?.showGrid ?? ref.watch(settingsProvider).valueOrNull?.showGrid ?? false;
    final continuousFeedback = ref.watch(settingsProvider).valueOrNull?.continuousFeedback ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          simulatorActive
              ? 'Simulator ${ref.watch(simulatorRunnerProvider).completedRuns + 1}/${ref.watch(simulatorRunnerProvider).totalRuns}'
              : '${(session.currentIndex + 1).clamp(1, session.totalTrials)} / ${session.totalTrials}',
        ),
        actions: [
          if (!simulatorActive)
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
                  ? (session.currentIndex + 1).clamp(0, session.totalTrials) /
                      session.totalTrials
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
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1,
                              crossAxisSpacing: showGrid ? 2 : 0,
                              mainAxisSpacing: showGrid ? 2 : 0,
                            ),
                            itemCount: 9,
                            itemBuilder: (context, index) {
                              final isActive = index == activePosition;
                              return Container(
                                decoration: BoxDecoration(
                                  color: showGrid
                                      ? (isActive
                                          ? Theme.of(context)
                                              .colorScheme.primary
                                          : Theme.of(context).cardColor)
                                      : (isActive
                                          ? Theme.of(context)
                                              .colorScheme.primary
                                          : Colors.transparent),
                                  border: showGrid
                                      ? Border.all(
                                          color: Theme.of(context)
                                              .dividerColor
                                              .withValues(alpha: 0.25),
                                          width: 1,
                                        )
                                      : null,
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: simulatorActive ? null : () => _onResponse(true, false),
                        style: continuousFeedback && _feedbackAudio != null
                            ? ElevatedButton.styleFrom(
                                side: BorderSide(
                                  color: _feedbackAudio!
                                      ? Colors.green.shade300
                                      : Colors.red.shade300,
                                  width: 2.5,
                                ),
                              )
                            : null,
                        child: Text(
                          AppStrings.audioMatch,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: simulatorActive ? null : () => _onResponse(false, true),
                        style: continuousFeedback && _feedbackVisual != null
                            ? ElevatedButton.styleFrom(
                                side: BorderSide(
                                  color: _feedbackVisual!
                                      ? Colors.green.shade300
                                      : Colors.red.shade300,
                                  width: 2.5,
                                ),
                              )
                            : null,
                        child: Text(
                          AppStrings.visualMatch,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
