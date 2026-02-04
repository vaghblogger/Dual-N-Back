import 'package:hive_flutter/hive_flutter.dart';

import '../models/session_result.dart';
import '../models/user_streak.dart';

const String _streakKey = 'user_streak';

class StatsRepository {
  StatsRepository(this.userId);

  final String userId;

  Box<SessionResult>? _sessionsBox;
  Box<UserStreak>? _streakBox;

  String get _sessionsBoxName => 'sessions_$userId';
  String get _streakBoxName => 'streak_$userId';

  Future<Box<SessionResult>> _getSessionsBox() async {
    _sessionsBox ??= await Hive.openBox<SessionResult>(_sessionsBoxName);
    return _sessionsBox!;
  }

  Future<Box<UserStreak>> _getStreakBox() async {
    _streakBox ??= await Hive.openBox<UserStreak>(_streakBoxName);
    return _streakBox!;
  }

  Future<void> saveSession(SessionResult session) async {
    final box = await _getSessionsBox();
    await box.add(session);
  }

  /// Replaces all sessions with the given list (e.g. after cloud pull).
  Future<void> replaceAllSessions(List<SessionResult> sessions) async {
    final box = await _getSessionsBox();
    await box.clear();
    for (final s in sessions) {
      await box.add(s);
    }
  }

  Future<List<SessionResult>> getAllSessions() async {
    final box = await _getSessionsBox();
    final list = box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Number of sessions completed today (same calendar day). Used for free-tier daily limit.
  Future<int> getSessionsCompletedToday() async {
    final sessions = await getAllSessions();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int count = 0;
    for (final s in sessions) {
      final day = DateTime(s.date.year, s.date.month, s.date.day);
      if (day == today) count++;
      if (day.isBefore(today)) break;
    }
    return count;
  }

  Future<double> getAverageN() async {
    final sessions = await getAllSessions();
    if (sessions.isEmpty) return 0.0;
    final sum = sessions.fold<double>(0, (s, e) => s + e.nLevel);
    return sum / sessions.length;
  }

  /// Highest N level ever achieved (max nLevel across all sessions). Returns 0 if no sessions.
  Future<int> getMaxN() async {
    final sessions = await getAllSessions();
    if (sessions.isEmpty) return 0;
    return sessions.map((s) => s.nLevel).reduce((a, b) => a > b ? a : b);
  }

  Future<UserStreak> getStreak() async {
    final box = await _getStreakBox();
    return box.get(_streakKey) ?? UserStreak();
  }

  Future<void> saveStreak(UserStreak streak) async {
    final box = await _getStreakBox();
    await box.put(_streakKey, streak);
  }

  /// Returns current streak count.
  Future<int> getCurrentStreak() async {
    final streak = await getStreak();
    return streak.currentStreak;
  }

  /// Returns the number of distinct days in the last 7 days (inclusive of today) on which the user completed at least one session.
  Future<int> getDaysTrainedInLast7Days() async {
    final completed = await getLast7DaysCompleted();
    return completed.where((c) => c).length;
  }

  /// Returns a list of 7 booleans: index 0 = 6 days ago, index 6 = today. True if user completed at least one session that day.
  Future<List<bool>> getLast7DaysCompleted() async {
    final sessions = await getAllSessions();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daySet = <int>{};
    for (final s in sessions) {
      final day = DateTime(s.date.year, s.date.month, s.date.day);
      final diff = today.difference(day).inDays;
      if (diff < 0 || diff > 6) continue;
      daySet.add(day.year * 10000 + day.month * 100 + day.day);
    }
    return List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return daySet.contains(d.year * 10000 + d.month * 100 + d.day);
    });
  }

  /// Sessions whose date falls within the last [days] days (inclusive of today).
  /// Result is sorted by date descending (newest first).
  Future<List<SessionResult>> getSessionsInLastDays(int days) async {
    final sessions = await getAllSessions();
    if (days <= 0) return [];
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    return sessions.where((s) => !s.date.isBefore(cutoff)).toList();
  }

  /// Heatmap data: day of week (1 = Monday .. 7 = Sunday) -> nLevel -> average accuracy (0.0–1.0).
  /// Cells with no sessions have 0.0. Used for "When do you perform best?" premium chart.
  Future<Map<int, Map<int, double>>> getHeatmapData() async {
    final sessions = await getAllSessions();
    // dayOfWeek -> nLevel -> (sum accuracy, count)
    final raw = <int, Map<int, ({double sum, int count})>>{};
    for (var d = 1; d <= 7; d++) {
      raw[d] = <int, ({double sum, int count})>{};
    }
    for (final s in sessions) {
      final dow = s.date.weekday;
      raw[dow] ??= <int, ({double sum, int count})>{};
      final prev = raw[dow]![s.nLevel];
      if (prev == null) {
        raw[dow]![s.nLevel] = (sum: s.accuracy, count: 1);
      } else {
        raw[dow]![s.nLevel] = (sum: prev.sum + s.accuracy, count: prev.count + 1);
      }
    }
    final result = <int, Map<int, double>>{};
    for (var d = 1; d <= 7; d++) {
      result[d] = <int, double>{};
      for (final e in raw[d]!.entries) {
        result[d]![e.key] = e.value.sum / e.value.count;
      }
    }
    return result;
  }

  /// True if user completed daily challenge today (same calendar day).
  bool isChallengeCompleteToday(UserStreak streak) {
    final last = streak.lastCompletedDate;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  /// Call when user completes daily challenge. Updates streak and saves.
  Future<void> incrementStreakOnComplete() async {
    final streak = await getStreak();
    final now = DateTime.now();
    final last = streak.lastCompletedDate;

    int newStreak;
    if (last == null) {
      newStreak = 1;
    } else {
      final yesterday = now.subtract(const Duration(days: 1));
      if (last.year == yesterday.year &&
          last.month == yesterday.month &&
          last.day == yesterday.day) {
        newStreak = streak.currentStreak + 1;
      } else if (last.year == now.year &&
          last.month == now.month &&
          last.day == now.day) {
        newStreak = streak.currentStreak;
      } else {
        newStreak = 1;
      }
    }

    final newLongest = newStreak > (streak.longestStreak) ? newStreak : streak.longestStreak;
    await saveStreak(UserStreak(
      currentStreak: newStreak,
      lastCompletedDate: now,
      longestStreak: newLongest,
    ));
  }

  /// Longest streak ever (from stored value; at least current streak for display).
  Future<int> getLongestStreak() async {
    final streak = await getStreak();
    return streak.currentStreak > streak.longestStreak
        ? streak.currentStreak
        : streak.longestStreak;
  }

  /// Closes and deletes sessions and streak boxes from disk. Use for full app reset.
  /// Callers must invalidate stats-related providers after this.
  /// Deletes by name so data is cleared even if boxes were never opened this session.
  Future<void> closeAndDeleteAll() async {
    if (_sessionsBox != null) {
      await _sessionsBox!.close();
      _sessionsBox = null;
    }
    await Hive.deleteBoxFromDisk(_sessionsBoxName);
    if (_streakBox != null) {
      await _streakBox!.close();
      _streakBox = null;
    }
    await Hive.deleteBoxFromDisk(_streakBoxName);
  }
}
