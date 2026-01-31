import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../logic/providers/game_provider.dart';
import '../../../logic/providers/stats_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentN = ref.watch(currentNProvider);
    final streakAsync = ref.watch(currentStreakProvider);
    final isCompleteTodayAsync = ref.watch(isChallengeCompleteTodayProvider);
    final daysThisWeekAsync = ref.watch(daysTrainedInLast7DaysProvider);
    final last7DaysAsync = ref.watch(last7DaysCompletedProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.bar_chart),
          iconSize: 36,
          onPressed: () => context.go('/stats'),
        ),
        title: Text(
          AppStrings.appTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            iconSize: 28,
            onPressed: () => context.go('/tutorial'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            iconSize: 36,
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              AppStrings.currentLevel.replaceAll('%d', '$currentN'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _DailyChallengeCard(
              streakAsync: streakAsync,
              isCompleteTodayAsync: isCompleteTodayAsync,
              onStart: () => _startGame(context, ref),
            ),
            const SizedBox(height: 24),
            _TrainYourBrainCard(onTap: () => context.go('/train')),
            const SizedBox(height: 24),
            _WeeklyStreakCard(
              daysThisWeekAsync: daysThisWeekAsync,
              last7DaysAsync: last7DaysAsync,
            ),
          ],
        ),
      ),
    );
  }

  void _startGame(BuildContext context, WidgetRef ref) {
    final n = ref.read(currentNProvider);
    ref.read(gameSessionProvider.notifier).startSession(n);
    context.go('/game');
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({
    required this.streakAsync,
    required this.isCompleteTodayAsync,
    required this.onStart,
  });

  final AsyncValue<int> streakAsync;
  final AsyncValue<bool> isCompleteTodayAsync;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final streak = streakAsync.valueOrNull ?? 0;
    final isComplete = isCompleteTodayAsync.valueOrNull ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppStrings.dailyChallenge,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (isComplete) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.maintainStreak.replaceAll('%d', '$streak'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (!isComplete)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onStart,
                  child: const Text(AppStrings.start),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrainYourBrainCard extends StatelessWidget {
  const _TrainYourBrainCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.trainYourBrain,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.trainYourBrainSubtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyStreakCard extends StatelessWidget {
  const _WeeklyStreakCard({
    required this.daysThisWeekAsync,
    required this.last7DaysAsync,
  });

  final AsyncValue<int> daysThisWeekAsync;
  final AsyncValue<List<bool>> last7DaysAsync;

  @override
  Widget build(BuildContext context) {
    final days = daysThisWeekAsync.valueOrNull ?? 0;
    final completed = last7DaysAsync.valueOrNull ?? List.filled(7, false);
    final today = DateTime.now();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.weeklyStreak,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.daysThisWeek.replaceAll('%d', '$days'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final date = today.subtract(Duration(days: 6 - i));
                final isCompleted = i < completed.length && completed[i];
                final isToday = i == 6;
                final label = isToday
                    ? 'Today'
                    : DateFormat('EEE').format(date);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? (theme.colorScheme.primary.withValues(alpha: 0.3))
                            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        border: Border.all(
                          color: isCompleted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(alpha: 0.5),
                          width: isCompleted ? 2 : 1,
                        ),
                      ),
                      child: isCompleted
                          ? Icon(Icons.check, size: 20, color: theme.colorScheme.primary)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 44,
                      child: Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.bold : null,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.weeklyStreakSubtitle,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
