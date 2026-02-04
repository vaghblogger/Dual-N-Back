import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/responsive_layout.dart';
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
  Timer? _stimulusTimer;
  Timer? _trialTimer;
  Timer? _autoPlayTimer;
  Timer? _advanceTimer; // short delay so in-flight taps get correct trial index
  Timer? _feedbackAudioTimer;
  Timer? _feedbackVisualTimer;
  Timer? _initialHoldTimer;

  bool _stimulusVisible = false;
  bool _paused = false;

  bool? _feedbackAudio;
  bool? _feedbackVisual;

  Stopwatch? _runStopwatch;
  AudioService? _audioService;

  static const int _stimulusMs = 500;
  /// Delay before advancing to next trial so taps inside the window are processed with correct index.
  static const int _advanceDelayMs = 120;

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
        if (!mounted || skipFocus) return;
        if (settings.focusMusicEnabled) {
          _audioService?.startFocusMusic();
        }
      }).catchError((_) {});
    });
  }

  @override
  void dispose() {
    _cancelAllTimers();
    _audioService?.stopFocusMusic();
    WakelockPlus.disable();
    super.dispose();
  }

  void _cancelAllTimers() {
    _stimulusTimer?.cancel();
    _trialTimer?.cancel();
    _advanceTimer?.cancel();
    _autoPlayTimer?.cancel();
    _feedbackAudioTimer?.cancel();
    _feedbackVisualTimer?.cancel();
    _initialHoldTimer?.cancel();
  }

  /* ================= RESPONSE HANDLING (IMPROVED) ================= */

  void _onResponse(bool audio, bool visual) {
    final session = ref.read(gameSessionProvider);
    if (session == null || session.isComplete || _paused) return;

    if (session.trials.isEmpty) return;

    final overrides = ref.read(sessionOverridesProvider);
    final settings = ref.read(settingsProvider).valueOrNull;
    final speedMultiplier =
        overrides?.speedMultiplier ?? settings?.speedMultiplier ?? 1.0;
    final trialDurationMs = (3000 / speedMultiplier).round();
    final slotMs = trialDurationMs + _advanceDelayMs;
    final elapsedMs = _runStopwatch?.elapsedMilliseconds ?? 0;

    // Attribute tap to the trial that was active at tap time (fixes scoring when tap is processed after advance)
    final idxByTime =
        (elapsedMs / slotMs).floor().clamp(0, session.trials.length - 1);

    // Reject if outside this trial's segment (before start or after end)
    final trialStartMs = idxByTime * slotMs;
    final trialEndMs = (idxByTime + 1) * slotMs;
    if (elapsedMs < trialStartMs || elapsedMs >= trialEndMs) return;

    final response = session.responses[idxByTime];

    // Prevent duplicate taps per channel
    if (audio && response.audio) return;
    if (visual && response.visual) return;

    ref.read(gameSessionProvider.notifier)
        .submitResponse(audio, visual, forIndex: idxByTime);

    final trial = session.trials[idxByTime];
    final updated = ref.read(gameSessionProvider)?.responses[idxByTime];
    final correctAudio = updated!.audio == trial.isAudioMatch;
    final correctVisual = updated.visual == trial.isVisualMatch;

    if (!(settings?.continuousFeedback ?? false)) return;

    if (audio) {
      _feedbackAudioTimer?.cancel();
      setState(() => _feedbackAudio = correctAudio);
      _feedbackAudioTimer = Timer(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() => _feedbackAudio = null);
      });
    }

    if (visual) {
      _feedbackVisualTimer?.cancel();
      setState(() => _feedbackVisual = correctVisual);
      _feedbackVisualTimer = Timer(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() => _feedbackVisual = null);
      });
    }
  }

  /* ================= TRIAL FLOW (IMPROVED) ================= */

  void _runTrial() {
    if (_paused) return;

    final session = ref.read(gameSessionProvider);
    if (session == null || session.isComplete) {
      _endSession();
      return;
    }

    final idx = session.currentIndex;
    if (idx >= session.trials.length) {
      _endSession();
      return;
    }

    final simulatorState = ref.read(simulatorRunnerProvider);
    if (idx == 0 && _runStopwatch == null) {
      _runStopwatch = Stopwatch()..start();
    }

    final overrides = ref.read(sessionOverridesProvider);
    final settings = ref.read(settingsProvider).valueOrNull;
    final speedMultiplier =
        overrides?.speedMultiplier ?? settings?.speedMultiplier ?? 1.0;

    final trialDurationMs = (3000 / speedMultiplier).round();
    final trial = session.trials[idx];

    _clearFeedback();

    setState(() => _stimulusVisible = true);
    _playLetter(trial.letter);

    if (simulatorState.isActive) {
      _autoPlayTimer?.cancel();
      _autoPlayTimer = Timer(const Duration(milliseconds: 300), () {
        final s = ref.read(gameSessionProvider);
        if (s == null) return;
        final r = s.responses[idx];
        if (r.audio || r.visual) return;
        ref.read(gameSessionProvider.notifier)
            .submitResponse(trial.isAudioMatch, trial.isVisualMatch, forIndex: idx);
      });
    }

    _stimulusTimer = Timer(const Duration(milliseconds: _stimulusMs), () {
      if (!mounted || _paused) return;
      setState(() => _stimulusVisible = false);
    });

    _trialTimer = Timer(Duration(milliseconds: trialDurationMs), () {
      if (!mounted || _paused) return;

      _advanceTimer?.cancel();
      _advanceTimer = Timer(const Duration(milliseconds: _advanceDelayMs), () {
        if (!mounted || _paused) return;
        final s = ref.read(gameSessionProvider);
        if (s == null) return;
        final nextIndex = s.currentIndex + 1;
        if (nextIndex < s.trials.length) {
          ref.read(gameSessionProvider.notifier).setCurrentIndex(nextIndex);
          _runTrial();
        } else {
          _endSession();
        }
      });
    });
  }

  void _clearFeedback() {
    _feedbackAudioTimer?.cancel();
    _feedbackVisualTimer?.cancel();
    setState(() {
      _feedbackAudio = null;
      _feedbackVisual = null;
    });
  }

  /* ================= AUDIO ================= */

  Future<void> _playLetter(String letter) async {
    try {
      await ref.read(audioServiceProvider).playLetter(letter);
    } catch (e, _) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.audioUnavailable)),
      );
    }
  }

  /* ================= PAUSE ================= */

  void _pause() {
    _paused = true;
    _cancelAllTimers();
    ref.read(gameSessionProvider.notifier).setPaused(true);

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.pause),
        content: const Text('Resume or quit?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _paused = false;
              ref.read(gameSessionProvider.notifier).setPaused(false);
              _runTrial();
            },
            child: const Text(AppStrings.resume),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
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

  /* ================= END SESSION (UNCHANGED LOGIC) ================= */

  Future<void> _endSession() async {
    _cancelAllTimers();
    _autoPlayTimer?.cancel();
    ref.read(audioServiceProvider).stopFocusMusic();

    final notifier = ref.read(gameSessionProvider.notifier);
    notifier.completeSession();
    final (audioScore, visualScore, totalAccuracy) =
        notifier.calculateScore();
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
        final runnerStateNow = ref.read(simulatorRunnerProvider);

        ref.read(gameSessionProvider.notifier).startSession(
          next.n,
          trialsPerSession: runnerStateNow.trialsPerSession,
        );

        ref.read(lastSessionSummaryProvider.notifier).state = null;

        if (!mounted) return;
        setState(() {
          _stimulusVisible = false;
        });

        _runStopwatch = Stopwatch()..start();
        _runTrial();
        return;
      }

      ref.read(lastSessionSummaryProvider.notifier).state =
          SessionSummaryData(
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
    ref.read(lastSessionSummaryProvider.notifier).state =
        SessionSummaryData(
      nLevel: session.nLevel,
      audioScore: audioScore,
      visualScore: visualScore,
      totalAccuracy: totalAccuracy,
      newN: newN,
      isAutoN: isAutoN,
    );

    ref.read(sessionOverridesProvider.notifier).state = null;
    context.go('/session-summary');
  }

  /* ================= BUILD (UNCHANGED UI) ================= */

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);

    if (session == null) {
      if (!ref.read(simulatorRunnerProvider).isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/home');
        });
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (session.currentIndex == 0 &&
        !session.isComplete &&
        _stimulusTimer == null &&
        _initialHoldTimer == null) {
      _initialHoldTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        _runTrial();
      });
    }

    final trial = session.currentTrial;
    final activePosition =
        _stimulusVisible && trial != null ? trial.position : -1;

    final simulatorActive = ref.watch(simulatorRunnerProvider).isActive;
    final overrides = ref.watch(sessionOverridesProvider);
    final showGrid =
        overrides?.showGrid ??
            ref.watch(settingsProvider).valueOrNull?.showGrid ??
            false;
    final continuousFeedback =
        ref.watch(settingsProvider).valueOrNull?.continuousFeedback ??
            false;

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
                  ? (session.currentIndex + 1)
                          .clamp(0, session.totalTrials) /
                      session.totalTrials
                  : 0,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                AppStrings.trainingAtN.replaceAll(
                  '%d',
                  '${session.nLevel.clamp(1, 16)}',
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: EdgeInsets.all(ResponsiveLayout.gridPadding(context)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: showGrid ? 2 : 0,
                              mainAxisSpacing: showGrid ? 2 : 0,
                            ),
                            itemCount: 9,
                            itemBuilder: (_, index) {
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
                                size: ResponsiveLayout.gameGridCenterIconSize(context),
                                color:
                                    Theme.of(context).colorScheme.onSurface,
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
              padding: EdgeInsets.fromLTRB(
                ResponsiveLayout.buttonRowHorizontalPadding(context),
                0,
                ResponsiveLayout.buttonRowHorizontalPadding(context),
                ResponsiveLayout.buttonRowBottomPadding(context),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: simulatorActive
                          ? null
                          : () => _onResponse(true, false),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveLayout.buttonVerticalPadding(context),
                          horizontal: ResponsiveLayout.buttonHorizontalPadding(context),
                        ),
                        minimumSize: Size(0, ResponsiveLayout.buttonMinHeight(context)),
                        textStyle: TextStyle(
                          fontSize: ResponsiveLayout.buttonFontSize(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ).copyWith(
                        side: continuousFeedback && _feedbackAudio != null
                            ? WidgetStateProperty.all(BorderSide(
                                color: _feedbackAudio!
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                                width: 2.5,
                              ))
                            : null,
                      ),
                      child: Text(AppStrings.audioMatch),
                    ),
                  ),
                  SizedBox(width: ResponsiveLayout.buttonRowHorizontalPadding(context)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: simulatorActive
                          ? null
                          : () => _onResponse(false, true),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveLayout.buttonVerticalPadding(context),
                          horizontal: ResponsiveLayout.buttonHorizontalPadding(context),
                        ),
                        minimumSize: Size(0, ResponsiveLayout.buttonMinHeight(context)),
                        textStyle: TextStyle(
                          fontSize: ResponsiveLayout.buttonFontSize(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ).copyWith(
                        side: continuousFeedback &&
                                _feedbackVisual != null
                            ? WidgetStateProperty.all(BorderSide(
                                color: _feedbackVisual!
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                                width: 2.5,
                              ))
                            : null,
                      ),
                      child: Text(AppStrings.visualMatch),
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

