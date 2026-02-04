import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/session_result.dart';
import '../../data/models/user_streak.dart';
import 'game_provider.dart';

final allSessionsProvider = FutureProvider<List<SessionResult>>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getAllSessions();
});

final averageNProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getAverageN();
});

/// Highest N level ever achieved (from session history). Used for "Current Level" display.
final highestNProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getMaxN();
});

final currentStreakProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getCurrentStreak();
});

/// Longest streak ever (for display in overview).
final longestStreakProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getLongestStreak();
});

final streakDataProvider = FutureProvider<UserStreak>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getStreak();
});

final isChallengeCompleteTodayProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  final streak = await repo.getStreak();
  return repo.isChallengeCompleteToday(streak);
});

final daysTrainedInLast7DaysProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getDaysTrainedInLast7Days();
});

/// List of 7 booleans: index 0 = 6 days ago, index 6 = today. True if user completed at least one session that day.
final last7DaysCompletedProvider = FutureProvider<List<bool>>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getLast7DaysCompleted();
});

/// Sessions completed today (same calendar day). Used for free-tier daily limit (2/day).
final sessionsCompletedTodayProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getSessionsCompletedToday();
});

/// Sessions in the last [days] days (7, 30, or 90). For premium trend charts.
final sessionsInLastDaysProvider =
    FutureProvider.family<List<SessionResult>, int>((ref, days) async {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getSessionsInLastDays(days);
});

/// Heatmap: day of week (1–7) -> nLevel -> avg accuracy. Premium only.
/// [days] 0 or null = all time, 30 = last 30 days, 90 = last 90 days.
final heatmapDataProvider =
    FutureProvider.family<Map<int, Map<int, double>>, int>((ref, days) async {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getHeatmapData(lastDays: days == 0 ? null : days);
});
