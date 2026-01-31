import 'package:hive_flutter/hive_flutter.dart';

import '../models/session_result.dart';
import '../models/user_streak.dart';

const String _sessionsBoxName = 'sessions';
const String _streakBoxName = 'streak';
const String _streakKey = 'user_streak';

class StatsRepository {
  Box<SessionResult>? _sessionsBox;
  Box<UserStreak>? _streakBox;

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

  Future<List<SessionResult>> getAllSessions() async {
    final box = await _getSessionsBox();
    final list = box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<double> getAverageN() async {
    final sessions = await getAllSessions();
    if (sessions.isEmpty) return 0.0;
    final sum = sessions.fold<double>(0, (s, e) => s + e.nLevel);
    return sum / sessions.length;
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

    await saveStreak(UserStreak(
      currentStreak: newStreak,
      lastCompletedDate: now,
    ));
  }
}
