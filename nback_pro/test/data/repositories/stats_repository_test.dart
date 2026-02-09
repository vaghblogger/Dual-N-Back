import 'package:flutter_test/flutter_test.dart';
import 'package:nback_pro/src/data/models/session_result.dart';
import 'package:nback_pro/src/data/models/user_streak.dart';
import 'package:nback_pro/src/data/repositories/stats_repository.dart';
import '../../test_helpers.dart';

void main() {
  setUpAll(() async {
    await initHiveForTest();
  });

  tearDownAll(() async {
    await closeHiveForTest();
  });

  group('StatsRepository', () {
    late StatsRepository repo;

    setUp(() {
      repo = StatsRepository(nextTestUserId);
    });

    tearDown(() async {
      await repo.closeAndDeleteAll();
    });

    test('saveSession and getAllSessions order by date desc', () async {
      final now = DateTime.now();
      await repo.saveSession(SessionResult(
        date: now.subtract(const Duration(days: 1)),
        nLevel: 1,
        accuracy: 0.8,
      ));
      await repo.saveSession(SessionResult(
        date: now,
        nLevel: 2,
        accuracy: 0.9,
      ));
      await repo.saveSession(SessionResult(
        date: now.subtract(const Duration(days: 2)),
        nLevel: 1,
        accuracy: 0.7,
      ));
      final list = await repo.getAllSessions();
      expect(list.length, 3);
      expect(list[0].date.isAfter(list[1].date), true);
      expect(list[1].date.isAfter(list[2].date), true);
      expect(list[0].nLevel, 2);
    });

    test('getSessionsCompletedToday counts same calendar day', () async {
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day, 12, 0);
      await repo.saveSession(SessionResult(
        date: todayOnly,
        nLevel: 1,
        accuracy: 0.8,
      ));
      await repo.saveSession(SessionResult(
        date: todayOnly.add(const Duration(hours: 1)),
        nLevel: 1,
        accuracy: 0.9,
      ));
      final count = await repo.getSessionsCompletedToday();
      expect(count, 2);
    });

    test('getSessionsCompletedToday next day is 0', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await repo.saveSession(SessionResult(
        date: yesterday,
        nLevel: 1,
        accuracy: 0.8,
      ));
      final count = await repo.getSessionsCompletedToday();
      expect(count, 0);
    });

    test('getLast7DaysCompleted returns 7 booleans, index 6 is today', () async {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day, 10, 0);
      await repo.saveSession(SessionResult(
        date: todayDate,
        nLevel: 1,
        accuracy: 0.8,
      ));
      final completed = await repo.getLast7DaysCompleted();
      expect(completed.length, 7);
      expect(completed[6], true);
    });

    test('getHeatmapData empty sessions returns structure with 0.0', () async {
      final heatmap = await repo.getHeatmapData();
      expect(heatmap.length, 7);
      for (var d = 1; d <= 7; d++) {
        expect(heatmap[d], isNotNull);
        expect(heatmap[d]!.isEmpty, true);
      }
    });

    test('getHeatmapData with sessions returns dayOfWeek and nLevel avg', () async {
      final now = DateTime.now();
      await repo.saveSession(SessionResult(
        date: now,
        nLevel: 2,
        accuracy: 0.8,
      ));
      await repo.saveSession(SessionResult(
        date: now.add(const Duration(hours: 1)),
        nLevel: 2,
        accuracy: 1.0,
      ));
      final heatmap = await repo.getHeatmapData();
      final dow = now.weekday;
      expect(heatmap[dow]![2], 0.9);
    });

    test('getHeatmapData with lastDays filters', () async {
      final now = DateTime.now();
      await repo.saveSession(SessionResult(
        date: now,
        nLevel: 1,
        accuracy: 0.5,
      ));
      final heatmapAll = await repo.getHeatmapData(lastDays: null);
      final heatmap30 = await repo.getHeatmapData(lastDays: 30);
      expect(heatmapAll.length, 7);
      expect(heatmap30.length, 7);
    });

    test('incrementStreakOnComplete first time sets streak 1', () async {
      await repo.incrementStreakOnComplete();
      final streak = await repo.getStreak();
      expect(streak.currentStreak, 1);
      expect(streak.lastCompletedDate, isNotNull);
      expect(streak.longestStreak, 1);
    });

    test('incrementStreakOnComplete same day does not increment', () async {
      await repo.incrementStreakOnComplete();
      await repo.incrementStreakOnComplete();
      final streak = await repo.getStreak();
      expect(streak.currentStreak, 1);
    });

    test('getMaxN empty returns 0', () async {
      expect(await repo.getMaxN(), 0);
    });

    test('getMaxN returns max nLevel', () async {
      final now = DateTime.now();
      await repo.saveSession(SessionResult(date: now, nLevel: 1, accuracy: 0.8));
      await repo.saveSession(SessionResult(date: now.add(const Duration(hours: 1)), nLevel: 5, accuracy: 0.9));
      await repo.saveSession(SessionResult(date: now.add(const Duration(hours: 2)), nLevel: 3, accuracy: 0.7));
      expect(await repo.getMaxN(), 5);
    });

    test('getAverageN empty returns 0', () async {
      expect(await repo.getAverageN(), 0.0);
    });

    test('getAverageN returns average', () async {
      final now = DateTime.now();
      await repo.saveSession(SessionResult(date: now, nLevel: 2, accuracy: 0.8));
      await repo.saveSession(SessionResult(date: now.add(const Duration(hours: 1)), nLevel: 4, accuracy: 0.9));
      expect(await repo.getAverageN(), 3.0);
    });

    test('replaceAllSessions clears and adds list', () async {
      final now = DateTime.now();
      await repo.saveSession(SessionResult(date: now, nLevel: 1, accuracy: 0.8));
      await repo.replaceAllSessions([
        SessionResult(date: now.add(const Duration(days: 1)), nLevel: 3, accuracy: 0.9),
      ]);
      final list = await repo.getAllSessions();
      expect(list.length, 1);
      expect(list[0].nLevel, 3);
    });

    test('closeAndDeleteAll then getStreak returns default', () async {
      await repo.incrementStreakOnComplete();
      await repo.closeAndDeleteAll();
      final repo2 = StatsRepository(repo.userId);
      final streak = await repo2.getStreak();
      expect(streak.currentStreak, 0);
      expect(streak.lastCompletedDate, isNull);
      await repo2.closeAndDeleteAll();
    });
  });
}
