import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/services/audio_service.dart';
import '../../../logic/providers/audio_service_provider.dart';
import '../../../logic/providers/game_provider.dart';

/// Pre-game: optional focus music (1, 2, or 3 min) with visible timer, then music stops,
/// then 3-2-1-Go countdown, then navigate to game; game screen holds 2 s before first pattern.
class PreGameScreen extends ConsumerStatefulWidget {
  const PreGameScreen({super.key, required this.n, this.fromDailyChallenge = false});

  final int n;
  final bool fromDailyChallenge;

  @override
  ConsumerState<PreGameScreen> createState() => _PreGameScreenState();
}

class _PreGameScreenState extends ConsumerState<PreGameScreen> {
  static const _countdownSteps = [3, 2, 1]; // then "Go"

  /// Focus music durations in seconds: 60 (1 min), 120 (2 min), 180 (3 min).
  static const _focusMusicDurations = [60, 120, 180];

  static const _inspirationMessages = [
    'Clear your mind. Focus.\nYou\'ve got this.',
    'Breathe. Let go of the noise.\nNow focus.',
    'One step at a time.\nYou\'re ready.',
    'Find your calm.\nThen bring your best.',
    'Quiet the mind.\nSharpen the focus.',
  ];

  Timer? _musicTimer;
  int _remainingSeconds = 0; // countdown while music plays
  bool _musicPlaying = false;
  int? _countdownValue; // 3, 2, 1 or null when showing "Go"
  bool _showGo = false;
  bool _showCountdown = false;
  bool _starting = false;
  bool _didPlayFocusMusic = false;
  AudioService? _audioService;
  late String _inspirationMessage;

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(audioServiceProvider);
    final rng = Random();
    _inspirationMessage = _inspirationMessages[rng.nextInt(_inspirationMessages.length)];
  }

  @override
  void dispose() {
    _musicTimer?.cancel();
    _audioService?.stopFocusMusic();
    super.dispose();
  }

  /// Start focus music for [durationSeconds] and show countdown. Music stops before 3-2-1.
  Future<void> _startFocusMusic(int durationSeconds) async {
    if (_musicPlaying) return;
    setState(() {
      _musicPlaying = true;
      _didPlayFocusMusic = true;
      _remainingSeconds = durationSeconds;
    });
    await ref.read(audioServiceProvider).startFocusMusic();
    if (!mounted) return;
    _musicTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds <= 0) {
          _musicTimer?.cancel();
          _musicTimer = null;
          _musicPlaying = false;
          _onMusicFinished();
          return;
        }
        _remainingSeconds--;
      });
    });
  }

  void _onMusicFinished() {
    ref.read(audioServiceProvider).stopFocusMusic();
    if (!mounted) return;
    _runCountdown();
  }

  /// Skip music: stop immediately, then run 3-2-1-Go.
  Future<void> _skipMusic() async {
    _musicTimer?.cancel();
    _musicTimer = null;
    setState(() => _musicPlaying = false);
    await ref.read(audioServiceProvider).stopFocusMusic();
    if (!mounted) return;
    _runCountdown();
  }

  void _runCountdown() {
    setState(() {
      _showCountdown = true;
      _countdownValue = _countdownSteps.first;
      _showGo = false;
    });
    _countdownStep(0);
  }

  void _countdownStep(int index) {
    if (index >= _countdownSteps.length) {
      _showGoThenStartGame();
      return;
    }
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _countdownValue = _countdownSteps[index]);
      _countdownStep(index + 1);
    });
  }

  void _showGoThenStartGame() {
    setState(() {
      _countdownValue = null;
      _showGo = true;
    });
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      _startGame();
    });
  }

  void _startGame() {
    if (_starting) return;
    _starting = true;
    if (_didPlayFocusMusic) {
      ref.read(skipFocusMusicThisSessionProvider.notifier).state = true;
    }
    ref.read(gameSessionProvider.notifier).startSession(widget.n);
    context.go('/game');
  }

  void _skipToCountdown() {
    _runCountdown();
  }

  /// Exit to home: stop timer and music, then navigate.
  Future<void> _exitToHome() async {
    _musicTimer?.cancel();
    _musicTimer = null;
    setState(() => _musicPlaying = false);
    await ref.read(audioServiceProvider).stopFocusMusic();
    if (!mounted) return;
    context.go('/home');
  }

  String get _remainingLabel {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_showCountdown) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: _showGo
                ? Text(
                    'Go',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 120,
                        ),
                  )
                : Text(
                    _countdownValue != null ? '$_countdownValue' : '',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 120,
                        ),
                  ),
          ),
        ),
      );
    }

    if (_musicPlaying) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Focus music'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _exitToHome,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    _remainingLabel,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 64,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'remaining',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: _skipMusic,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                  child: const Text('Skip to Training'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get ready'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              if (widget.fromDailyChallenge) ...[
                Center(
                  child: Text(
                    AppStrings.todayYouWillTrainOnN.replaceAll('%d', '${widget.n}'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                _inspirationMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Play Music',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              ..._focusMusicDurations.map((seconds) {
                final label = seconds == 60
                    ? '1 Min'
                    : seconds == 120
                        ? '2 mins'
                        : '3 mins';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton(
                    onPressed: () => _startFocusMusic(seconds),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: Text(label),
                  ),
                );
              }),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _skipToCountdown,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                ),
                child: const Text('Skip to Training'),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
