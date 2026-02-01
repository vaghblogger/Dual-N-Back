import 'package:flutter/foundation.dart';
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
    final highestNAsync = ref.watch(highestNProvider);
    final highestN = highestNAsync.valueOrNull ?? currentN;
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
              AppStrings.currentLevel.replaceAll('%d', '$highestN'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (highestN > 0 && currentN < highestN) ...[
              const SizedBox(height: 4),
              Text(
                AppStrings.playingAt.replaceAll('%d', '$currentN'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            _DailyChallengeCard(
              highestN: highestN,
              streakAsync: streakAsync,
              isCompleteTodayAsync: isCompleteTodayAsync,
              onStart: (n) => _startGame(context, ref, n),
            ),
            const SizedBox(height: 24),
            _TrainYourBrainCard(onTap: () => context.go('/train')),
            const SizedBox(height: 24),
            _WeeklyStreakCard(
              daysThisWeekAsync: daysThisWeekAsync,
              last7DaysAsync: last7DaysAsync,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.go('/debug'),
                icon: const Icon(Icons.bug_report, size: 20),
                label: const Text('Run simulator suite (Debug)'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startGame(BuildContext context, WidgetRef ref, int n) {
    ref.read(gameSessionProvider.notifier).startSession(n);
    context.go('/game');
  }
}

class _DailyChallengeCard extends StatefulWidget {
  const _DailyChallengeCard({
    required this.highestN,
    required this.streakAsync,
    required this.isCompleteTodayAsync,
    required this.onStart,
  });

  final int highestN;
  final AsyncValue<int> streakAsync;
  final AsyncValue<bool> isCompleteTodayAsync;
  final void Function(int n) onStart;

  @override
  State<_DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends State<_DailyChallengeCard> {
  static const int _minN = 1;
  static const int _maxN = 15;

  late int _selectedN;
  bool _initializedFromHighest = false;

  @override
  void initState() {
    super.initState();
    _selectedN = widget.highestN > 0 ? widget.highestN.clamp(_minN, _maxN) : _minN;
    if (widget.highestN > 0) _initializedFromHighest = true;
  }

  @override
  void didUpdateWidget(_DailyChallengeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highestN > 0 && !_initializedFromHighest) {
      _initializedFromHighest = true;
      setState(() => _selectedN = widget.highestN.clamp(_minN, _maxN));
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = widget.streakAsync.valueOrNull ?? 0;
    final isComplete = widget.isCompleteTodayAsync.valueOrNull ?? false;

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
            if (!isComplete) ...[
              const SizedBox(height: 12),
              Text(
                AppStrings.dailyChallengeLevel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _selectedN > _minN
                        ? () => setState(() => _selectedN--)
                        : null,
                  ),
                  Text(
                    'N = $_selectedN',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _selectedN < _maxN
                        ? () => setState(() => _selectedN++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onStart(_selectedN),
                  child: const Text(AppStrings.start),
                ),
              ),
            ],
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
