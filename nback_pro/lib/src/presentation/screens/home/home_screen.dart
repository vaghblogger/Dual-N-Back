import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../logic/providers/game_provider.dart';
import '../../../logic/providers/stats_provider.dart';
import '../../../logic/providers/subscription_provider.dart';
import '../../widgets/paywall_dialog.dart';
import '../../widgets/responsive_weekly_streak_row.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentN = ref.watch(currentNProvider);
    final highestNAsync = ref.watch(highestNProvider);
    final highestN = highestNAsync.valueOrNull ?? currentN;
    final streakAsync = ref.watch(currentStreakProvider);
    final isCompleteTodayAsync = ref.watch(isChallengeCompleteTodayProvider);
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
        padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 360 ? 12 : 16),
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
            _WeeklyStreakCard(last7DaysAsync: last7DaysAsync),
            const SizedBox(height: 24),
            _DailyChallengeCard(
              currentN: currentN,
              highestN: highestN,
              streakAsync: streakAsync,
              isCompleteTodayAsync: isCompleteTodayAsync,
              onStart: (n) => _startGame(context, ref, n),
            ),
            const SizedBox(height: 24),
            _TrainYourBrainCard(
              isPremium: ref.watch(isPremiumProvider),
              onTap: () {
                if (ref.read(isPremiumProvider)) {
                  context.go('/train');
                } else {
                  showPaywallDialog(context, paywallContext: PaywallContext.train);
                }
              },
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
    ref.read(currentNProvider.notifier).state = n;
    context.go('/pre-game', extra: {'n': n, 'fromDailyChallenge': true});
  }
}

class _DailyChallengeCard extends StatefulWidget {
  const _DailyChallengeCard({
    required this.currentN,
    required this.highestN,
    required this.streakAsync,
    required this.isCompleteTodayAsync,
    required this.onStart,
  });

  final int currentN;
  final int highestN;
  final AsyncValue<int> streakAsync;
  final AsyncValue<bool> isCompleteTodayAsync;
  final void Function(int n) onStart;

  @override
  State<_DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends State<_DailyChallengeCard> {
  late int _selectedN;

  int get _maxN => widget.highestN < 1 ? 1 : widget.highestN.clamp(1, 15);

  @override
  void initState() {
    super.initState();
    _selectedN = widget.currentN.clamp(1, _maxN);
  }

  @override
  void didUpdateWidget(covariant _DailyChallengeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedN = _selectedN.clamp(1, _maxN);
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = widget.isCompleteTodayAsync.valueOrNull ?? false;
    final maxN = _maxN;

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
            if (isComplete) ...[
              Text(
                AppStrings.dailyChallengeCompleted,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.dailyChallengeComeBackTomorrow,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ] else ...[
              Text(
                AppStrings.maintainYourStreak,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.dailyChallengeChooseLevelUpTo
                    .replaceAll('%d', '$maxN'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.dailyChallengeLevel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    icon: const Icon(Icons.remove),
                    iconSize: 28,
                    onPressed: _selectedN > 1
                        ? () => setState(() => _selectedN--)
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Text(
                    'N = $_selectedN',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 20),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    iconSize: 28,
                    onPressed: _selectedN < maxN
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
  const _TrainYourBrainCard({
    required this.isPremium,
    required this.onTap,
  });

  final bool isPremium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, size: 24, color: theme.colorScheme.onSurface),
                const SizedBox(width: 8),
                Text(
                  AppStrings.trainYourBrain,
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.trainYourBrainSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                child: const Text(AppStrings.startTraining),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyStreakCard extends StatelessWidget {
  const _WeeklyStreakCard({
    required this.last7DaysAsync,
  });

  final AsyncValue<List<bool>> last7DaysAsync;

  @override
  Widget build(BuildContext context) {
    final completed = last7DaysAsync.valueOrNull ?? List.filled(7, false);
    final padding = MediaQuery.sizeOf(context).width < 360 ? 12.0 : 16.0;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: ResponsiveWeeklyStreakRow(last7Days: completed),
      ),
    );
  }
}
