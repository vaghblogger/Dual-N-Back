import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/session_result.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/services/sync_service.dart';
import '../game_engine/nback_engine.dart';
import '../game_engine/trial.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';
import 'subscription_provider.dart';

final nBackEngineProvider = Provider<NBackEngine>((ref) => NBackEngine());

/// Current effective N level (for display). With Auto-N this is updated after each session.
final currentNProvider = StateProvider<int>((ref) => 1);

/// Session-only overrides for speed and grid. Set when starting from Train screen;
/// cleared when the session ends. When null, game uses stored settings.
class SessionOverrides {
  final double speedMultiplier;
  final bool showGrid;

  const SessionOverrides({
    required this.speedMultiplier,
    required this.showGrid,
  });
}

final sessionOverridesProvider =
    StateProvider<SessionOverrides?>((ref) => null);

/// When true, game screen must not start focus music (e.g. after pre-game focus phase).
final skipFocusMusicThisSessionProvider = StateProvider<bool>((ref) => false);

/// Session state: trials, current index, responses, status.
class GameSessionState {
  final List<Trial> trials;
  final int currentIndex;
  final List<({bool audio, bool visual})> responses;
  final int nLevel;
  final bool isPaused;
  final bool isComplete;

  const GameSessionState({
    required this.trials,
    required this.currentIndex,
    required this.responses,
    required this.nLevel,
    this.isPaused = false,
    this.isComplete = false,
  });

  Trial? get currentTrial =>
      currentIndex >= 0 && currentIndex < trials.length ? trials[currentIndex] : null;
  int get totalTrials => trials.length;
}

final gameSessionProvider =
    StateNotifierProvider<GameSessionNotifier, GameSessionState?>((ref) {
  return GameSessionNotifier(ref);
});

class GameSessionNotifier extends StateNotifier<GameSessionState?> {
  GameSessionNotifier(this._ref) : super(null);

  final Ref _ref;

  static const int _maxN = 15;

  /// [trialsPerSession] if set (e.g. simulator) overrides default 20 + n. Must be >= n + 1.
  void startSession(int n, {int? trialsPerSession}) {
    final engine = _ref.read(nBackEngineProvider);
    final totalTrials = (trialsPerSession ?? (20 + n)).clamp(n + 1, 999);
    final trials = engine.generateSession(n, totalTrials);
    state = GameSessionState(
      trials: trials,
      currentIndex: 0,
      responses: List.generate(trials.length, (_) => (audio: false, visual: false)),
      nLevel: n.clamp(1, _maxN),
    );
  }

  void setCurrentIndex(int index) {
    if (state == null) return;
    state = GameSessionState(
      trials: state!.trials,
      currentIndex: index,
      responses: state!.responses,
      nLevel: state!.nLevel,
      isPaused: state!.isPaused,
      isComplete: state!.isComplete,
    );
  }

  void submitResponse(bool audio, bool visual) {
    if (state == null) return;
    final i = state!.currentIndex;
    if (i < 0 || i >= state!.responses.length) return;
    final resp = List<({bool audio, bool visual})>.from(state!.responses);
    resp[i] = (audio: resp[i].audio || audio, visual: resp[i].visual || visual);
    state = GameSessionState(
      trials: state!.trials,
      currentIndex: state!.currentIndex,
      responses: resp,
      nLevel: state!.nLevel,
      isPaused: state!.isPaused,
      isComplete: state!.isComplete,
    );
  }

  void setPaused(bool paused) {
    if (state == null) return;
    state = GameSessionState(
      trials: state!.trials,
      currentIndex: state!.currentIndex,
      responses: state!.responses,
      nLevel: state!.nLevel,
      isPaused: paused,
      isComplete: state!.isComplete,
    );
  }

  void completeSession() {
    if (state == null) return;
    state = GameSessionState(
      trials: state!.trials,
      currentIndex: state!.currentIndex,
      responses: state!.responses,
      nLevel: state!.nLevel,
      isPaused: false,
      isComplete: true,
    );
  }

  void endSession() {
    state = null;
  }

  /// Returns (audioScore, visualScore, totalAccuracy) in 0.0–1.0.
  ///
  /// Scoring rules (standard Dual N-Back):
  /// - Not tapping = "no match". So (audio: false, visual: false) on a trial is
  ///   correct when the trial has no audio match and no visual match.
  /// - Tapping Audio Match = "audio match"; correct when trial is audio match.
  /// - Tapping Visual Match = "visual match"; correct when trial is visual match.
  /// - If the user never tapped at all in the entire session, we treat that as
  ///   no engagement and return 0% (avoids inflating score by doing nothing).
  (double, double, double) calculateScore() {
    final s = state;
    if (s == null || s.trials.isEmpty) return (0.0, 0.0, 0.0);
    final total = s.trials.length;
    final anyTap = s.responses.any((r) => r.audio || r.visual);
    if (!anyTap) {
      // No tap in entire session: no engagement, do not inflate score
      return (0.0, 0.0, 0.0);
    }
    int audioCorrect = 0;
    int visualCorrect = 0;
    for (int i = 0; i < total; i++) {
      final t = s.trials[i];
      final r = s.responses[i];
      // Correct = (said match and was match) OR (said no match and was no match)
      if ((r.audio && t.isAudioMatch) || (!r.audio && !t.isAudioMatch)) {
        audioCorrect++;
      }
      if ((r.visual && t.isVisualMatch) || (!r.visual && !t.isVisualMatch)) {
        visualCorrect++;
      }
    }
    final audioScore = total > 0 ? audioCorrect / total : 0.0;
    final visualScore = total > 0 ? visualCorrect / total : 0.0;
    final totalAccuracy = (audioScore + visualScore) / 2;
    return (audioScore, visualScore, totalAccuracy);
  }

  /// Adjusts N level based on accuracy (Auto-N). Call at end of session.
  /// Returns new N level. Capped at 3 for free users, _maxN for premium.
  /// Threshold: ≥70% move up, <70% move down.
  int adjustNLevel(double accuracy, bool isAutoNEnabled) {
    if (!isAutoNEnabled) return _ref.read(currentNProvider);
    final isPremium = _ref.read(isPremiumProvider);
    final cap = isPremium ? _maxN : 3;
    int current = _ref.read(currentNProvider);
    if (accuracy >= 0.70) {
      current = (current + 1).clamp(1, cap);
    } else if (accuracy < 0.70) {
      current = (current - 1).clamp(1, cap);
    }
    _ref.read(currentNProvider.notifier).state = current;
    return current;
  }
}

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final userId = ref.watch(currentStorageUserIdProvider);
  return StatsRepository(userId);
});

/// Data for the session summary screen. Set when session ends, cleared after viewing.
class SessionSummaryData {
  final int nLevel;
  final double audioScore;
  final double visualScore;
  final double totalAccuracy;
  final int newN;
  final bool isAutoN;

  const SessionSummaryData({
    required this.nLevel,
    required this.audioScore,
    required this.visualScore,
    required this.totalAccuracy,
    required this.newN,
    required this.isAutoN,
  });
}

final lastSessionSummaryProvider =
    StateProvider<SessionSummaryData?>((ref) => null);

/// Persists session result and streak; adjusts N if Auto-N. Call after session ends.
/// Firestore sync runs in the background so the summary screen is never blocked by
/// Firestore errors (e.g. API not enabled or permission denied).
Future<void> persistSession(WidgetRef ref, SessionResult result) async {
  final statsRepo = ref.read(statsRepositoryProvider);
  final settingsRepo = ref.read(settingsRepositoryProvider);
  final settings = await settingsRepo.getSettings();
  await statsRepo.saveSession(result);
  await statsRepo.incrementStreakOnComplete();
  final user = ref.read(currentUserProvider);
  if (user != null) {
    final uid = user.uid;
    final sync = SyncService();
    // Run Firestore push in background so summary always shows even if Firestore fails.
    Future(() async {
      await sync.pushSession(uid, result);
      final streak = await statsRepo.getStreak();
      await sync.pushStreak(uid, streak);
    });
  }
  final isPremium = ref.read(isPremiumProvider);
  final effectiveIsAutoN = isPremium ? settings.isAutoN : true;
  final gameNotifier = ref.read(gameSessionProvider.notifier);
  gameNotifier.adjustNLevel(result.accuracy, effectiveIsAutoN);
}
