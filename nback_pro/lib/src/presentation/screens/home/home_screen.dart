import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../logic/providers/game_provider.dart';
import '../../../logic/providers/settings_provider.dart';
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
    final settings = ref.watch(settingsProvider).valueOrNull;
    final isPremium = ref.watch(isPremiumProvider);
    final isAutoN = isPremium ? (settings?.isAutoN ?? true) : true;
    final manualN = isPremium ? (settings?.manualN ?? 1) : 1;
    final streakAsync = ref.watch(currentStreakProvider);
    final isCompleteTodayAsync = ref.watch(isChallengeCompleteTodayProvider);
    final last7DaysAsync = ref.watch(last7DaysCompletedProvider);

    if (isPremium && !isAutoN && settings != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(currentNProvider) != manualN) {
          ref.read(currentNProvider.notifier).state = manualN;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.bar_chart),
          iconSize: ResponsiveLayout.iconSizeAppBar(context),
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
            iconSize: ResponsiveLayout.iconSizeMedium(context),
            onPressed: () => context.go('/tutorial'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            iconSize: ResponsiveLayout.iconSizeAppBar(context),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveLayout.contentPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: ResponsiveLayout.spacing(context, 16)),
            Text(
              AppStrings.currentNLevelDisplay.replaceAll('%d', '$highestN'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveLayout.spacing(context, 24)),
            _WeeklyStreakCard(last7DaysAsync: last7DaysAsync),
            SizedBox(height: ResponsiveLayout.spacing(context, 24)),
            _DailyChallengeCard(
              currentN: currentN,
              highestN: highestN,
              isAutoN: isAutoN,
              manualN: manualN,
              streakAsync: streakAsync,
              isCompleteTodayAsync: isCompleteTodayAsync,
              onStart: (n) => _startGame(context, ref, n),
            ),
            SizedBox(height: ResponsiveLayout.spacing(context, 24)),
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
              SizedBox(height: ResponsiveLayout.spacing(context, 24)),
              OutlinedButton.icon(
                onPressed: () => context.go('/debug'),
                icon: Icon(Icons.bug_report, size: ResponsiveLayout.iconSizeSmall(context)),
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
    required this.isAutoN,
    required this.manualN,
    required this.streakAsync,
    required this.isCompleteTodayAsync,
    required this.onStart,
  });

  final int currentN;
  final int highestN;
  final bool isAutoN;
  final int manualN;
  final AsyncValue<int> streakAsync;
  final AsyncValue<bool> isCompleteTodayAsync;
  final void Function(int n) onStart;

  @override
  State<_DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends State<_DailyChallengeCard> {
  late int _selectedN;

  int get _maxN => widget.highestN < 1 ? 1 : widget.highestN.clamp(1, 14);

  /// Default to current level (highest N); user can tap − to go lower.
  int get _defaultN => _maxN;

  @override
  void initState() {
    super.initState();
    _selectedN = _defaultN;
  }

  @override
  void didUpdateWidget(covariant _DailyChallengeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When current level (highestN) loads or increases, default selection to it.
    if (widget.highestN > oldWidget.highestN) {
      _selectedN = _maxN;
    } else {
      _selectedN = _selectedN.clamp(1, _maxN);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = widget.isCompleteTodayAsync.valueOrNull ?? false;
    final maxN = _maxN;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveLayout.horizontalPadding(context)),
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
                  SizedBox(width: ResponsiveLayout.spacing(context, 8)),
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: ResponsiveLayout.iconSizeMedium(context)),
                ],
              ],
            ),
            SizedBox(height: ResponsiveLayout.spacing(context, 8)),
            if (isComplete) ...[
              Text(
                AppStrings.dailyChallengeCompleted,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              SizedBox(height: ResponsiveLayout.spacing(context, 4)),
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
              SizedBox(height: ResponsiveLayout.spacing(context, 4)),
              if (widget.isAutoN) ...[
                Text(
                  AppStrings.recommendedN.replaceAll('%d', '${widget.currentN}'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                SizedBox(height: ResponsiveLayout.spacing(context, 4)),
              ],
              Text(
                AppStrings.dailyChallengeChooseLevelUpTo
                    .replaceAll('%d', '$maxN'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              SizedBox(height: ResponsiveLayout.spacing(context, 12)),
              Text(
                AppStrings.dailyChallengeLevel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              SizedBox(height: ResponsiveLayout.spacing(context, 6)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    icon: const Icon(Icons.remove),
                    iconSize: ResponsiveLayout.iconSizeMedium(context),
                    onPressed: _selectedN > 1
                        ? () => setState(() => _selectedN--)
                        : null,
                  ),
                  SizedBox(width: ResponsiveLayout.spacing(context, 20)),
                  Text(
                    'N = $_selectedN',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(width: ResponsiveLayout.spacing(context, 20)),
                  _selectedN >= maxN
                      ? Tooltip(
                          message: AppStrings.dailyChallengePlusDisabled.replaceAll('%d', '$maxN'),
                          child: IconButton.filled(
                            icon: const Icon(Icons.add),
                            iconSize: ResponsiveLayout.iconSizeMedium(context),
                            onPressed: null,
                          ),
                        )
                      : IconButton.filled(
                          icon: const Icon(Icons.add),
                          iconSize: ResponsiveLayout.iconSizeMedium(context),
                          onPressed: () => setState(() => _selectedN++),
                        ),
                ],
              ),
              SizedBox(height: ResponsiveLayout.spacing(context, 12)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onStart(_selectedN.clamp(1, _maxN)),
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
    final pad = ResponsiveLayout.horizontalPadding(context);

    return Card(
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.fitness_center, size: ResponsiveLayout.iconSizeMedium(context), color: theme.colorScheme.onSurface),
                    SizedBox(width: ResponsiveLayout.spacing(context, 8)),
                    Text(
                      AppStrings.trainYourBrain,
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveLayout.spacing(context, 8)),
                Text(
                  AppStrings.trainYourBrainSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: ResponsiveLayout.spacing(context, 12)),
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
          Positioned(
            top: ResponsiveLayout.spacing(context, 12),
            right: ResponsiveLayout.spacing(context, 12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveLayout.spacing(context, 8),
                vertical: ResponsiveLayout.spacing(context, 4),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.9),
                    theme.colorScheme.tertiary.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    size: ResponsiveLayout.iconSizeSmall(context),
                    color: theme.colorScheme.onPrimary,
                  ),
                  SizedBox(width: ResponsiveLayout.spacing(context, 4)),
                  Text(
                    'PRO',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    final padding = ResponsiveLayout.horizontalPadding(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: ResponsiveWeeklyStreakRow(last7Days: completed),
      ),
    );
  }
}
