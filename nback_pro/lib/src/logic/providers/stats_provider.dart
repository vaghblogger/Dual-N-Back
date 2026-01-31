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

final currentStreakProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getCurrentStreak();
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
