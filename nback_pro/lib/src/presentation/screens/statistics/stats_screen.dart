import 'dart:io';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/models/session_result.dart';
import '../../../logic/providers/stats_provider.dart';
import '../../../logic/providers/subscription_provider.dart';
import '../../../presentation/widgets/paywall_dialog.dart';
import '../../../presentation/widgets/responsive_weekly_streak_row.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final sessionsAsync = ref.watch(allSessionsProvider);
    final highestNAsync = ref.watch(highestNProvider);
    final streakAsync = ref.watch(currentStreakProvider);
    final longestStreakAsync = ref.watch(longestStreakProvider);
    final last7DaysAsync = ref.watch(last7DaysCompletedProvider);
    final sessionsTodayAsync = ref.watch(sessionsCompletedTodayProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text(isPremium ? AppStrings.brainInsights : AppStrings.yourProgress),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sessions) {
          final highestN = highestNAsync.valueOrNull ?? 0;
          final streak = streakAsync.valueOrNull ?? 0;
          final longestStreak = longestStreakAsync.valueOrNull ?? 0;
          final last7Days = last7DaysAsync.valueOrNull ?? List.filled(7, false);
          final sessionsToday = sessionsTodayAsync.valueOrNull ?? 0;

          if (isPremium) {
            return _PremiumDashboard(
              sessions: sessions,
              highestN: highestN,
              streak: streak,
              longestStreak: longestStreak,
              last7Days: last7Days,
            );
          }
          return _FreeTeaser(
            sessions: sessions,
            highestN: highestN,
            streak: streak,
            longestStreak: longestStreak,
            last7Days: last7Days,
            sessionsToday: sessionsToday,
          );
        },
      ),
    );
  }
}

/// Free tier: hero metric, 7-day row, today summary, Pro insights card.
class _FreeTeaser extends StatelessWidget {
  const _FreeTeaser({
    required this.sessions,
    required this.highestN,
    required this.streak,
    required this.longestStreak,
    required this.last7Days,
    required this.sessionsToday,
  });

  final List<SessionResult> sessions;
  final int highestN;
  final int streak;
  final int longestStreak;
  final List<bool> last7Days;
  final int sessionsToday;

  @override
  Widget build(BuildContext context) {
    final lastSession = sessions.isNotEmpty ? sessions.first : null;
    final padding = MediaQuery.sizeOf(context).width < 360 ? 12.0 : 16.0;
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // First card: 2x2 grid (Highest N | Total Sessions; Current Streak | Longest Streak) with streak flame icons
          Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.leaderboard,
                                    size: 28,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$highestN',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.highestNLevel,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fitness_center,
                                    size: 28,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${sessions.length}',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.totalSessions,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    height: 24,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 28,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$streak',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.currentStreak,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 28,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$longestStreak',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.longestStreak,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Last 7 days — same style as Home Screen (Weekly Streak card)
          Card(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.weeklyStreak,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.daysThisWeek.replaceAll('%d', '${last7Days.where((c) => c).length}'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ResponsiveWeeklyStreakRow(last7Days: last7Days),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.weeklyStreakSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Today summary
          Text(
            AppStrings.sessionsToday.replaceAll('%d', '$sessionsToday'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (lastSession != null) ...[
            const SizedBox(height: 4),
            Text(
              AppStrings.lastSessionSummary
                  .replaceFirst('%d', '${lastSession.nLevel}')
                  .replaceFirst('%d', '${(lastSession.accuracy * 100).round()}'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 24),
          // Pro insights card
          _ProInsightsCard(
            onTap: () => showPaywallDialogProgress(context),
          ),
        ],
      ),
    );
  }
}

/// Pro insights teaser card: tap opens paywall.
class _ProInsightsCard extends StatelessWidget {
  const _ProInsightsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Blurred chart preview
              SizedBox(
                height: 100,
                width: double.infinity,
                child: CustomPaint(
                  painter: _DummyChartPainter(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                    height: 100,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.proInsightsTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.proInsightsDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: onTap,
                      child: const Text(AppStrings.unlockPro),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws a simple dummy line so the blurred preview looks like a chart.
class _DummyChartPainter extends CustomPainter {
  _DummyChartPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.5,
      size.width * 0.5,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.3,
      size.width,
      size.height * 0.2,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Premium: full dashboard (overview, 7-day, trend with 7d/30d/90d, dual-channel, heatmap, history).
class _PremiumDashboard extends ConsumerStatefulWidget {
  const _PremiumDashboard({
    required this.sessions,
    required this.highestN,
    required this.streak,
    required this.longestStreak,
    required this.last7Days,
  });

  final List<SessionResult> sessions;
  final int highestN;
  final int streak;
  final int longestStreak;
  final List<bool> last7Days;

  @override
  ConsumerState<_PremiumDashboard> createState() => _PremiumDashboardState();
}

class _PremiumDashboardState extends ConsumerState<_PremiumDashboard> {
  int _selectedTrendDays = 30;

  @override
  Widget build(BuildContext context) {
    final sessionsInRangeAsync = ref.watch(sessionsInLastDaysProvider(_selectedTrendDays));
    final heatmapAsync = ref.watch(heatmapDataProvider);

    final padding = MediaQuery.sizeOf(context).width < 360 ? 12.0 : 16.0;
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.overview,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _OverviewItem(
                          label: AppStrings.highestNLevel,
                          value: '${widget.highestN}',
                          emphasis: true,
                          leadingIcon: Icons.leaderboard,
                        ),
                      ),
                      Expanded(
                        child: _OverviewItem(
                          label: AppStrings.totalSessions,
                          value: '${widget.sessions.length}',
                          emphasis: false,
                          leadingIcon: Icons.fitness_center,
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    height: 24,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 28,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.streak}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.currentStreak,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 28,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.longestStreak}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.longestStreak,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Last 7 days — same style as Home Screen (Weekly Streak card)
          Card(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.weeklyStreak,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.daysThisWeek.replaceAll(
                        '%d', '${widget.last7Days.where((c) => c).length}'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ResponsiveWeeklyStreakRow(last7Days: widget.last7Days),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.weeklyStreakSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // N-Level trend with 7d / 30d / 90d selector
          Text(
            AppStrings.nLevelTrend,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7d')),
              ButtonSegment(value: 30, label: Text('30d')),
              ButtonSegment(value: 90, label: Text('90d')),
            ],
            selected: {_selectedTrendDays},
            onSelectionChanged: (Set<int> selected) {
              setState(() => _selectedTrendDays = selected.first);
            },
          ),
          const SizedBox(height: 8),
          sessionsInRangeAsync.when(
            loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
            error: (e, st) => const SizedBox(height: 120, child: Center(child: Text('Error loading trend'))),
            data: (sessionsInRange) {
              if (sessionsInRange.isEmpty) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'No sessions in this range',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 200,
                child: _NLevelChart(sessions: sessionsInRange),
              );
            },
          ),
          const SizedBox(height: 24),
          // Dual-channel: Audio vs Visual accuracy
          if (widget.sessions.any((s) => s.audioAccuracy != null || s.visualAccuracy != null)) ...[
            Text(
              AppStrings.dualChannelBreakdown,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.dualChannelSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: _DualChannelChart(
                sessions: widget.sessions.take(30).toList().reversed.toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Performance heatmap
          Text(
            AppStrings.performanceHeatmap,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.performanceHeatmapSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          heatmapAsync.when(
            loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
            error: (e, st) => const SizedBox(height: 120, child: Center(child: Text('Error loading heatmap'))),
            data: (heatmap) => _HeatmapGrid(heatmap: heatmap),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.sessionHistory,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showShareProgressStoryDialog(
                  context,
                  sessions: widget.sessions,
                  highestN: widget.highestN,
                  streak: widget.streak,
                ),
                icon: const Icon(Icons.share, size: 18),
                label: const Text(AppStrings.shareProgressStory),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.sessions.take(30).map((s) => _SessionTile(session: s)),
        ],
      ),
    );
  }
}

/// Shows dialog with progress story card and Share button; captures card as image and shares.
void _showShareProgressStoryDialog(
  BuildContext context, {
  required List<SessionResult> sessions,
  required int highestN,
  required int streak,
}) {
  final totalDays = sessions.isEmpty
      ? 0
      : sessions.map((s) => DateTime(s.date.year, s.date.month, s.date.day)).toSet().length;
  final avgAcc = sessions.isEmpty
      ? 0.0
      : sessions.fold<double>(0, (s, e) => s + e.accuracy) / sessions.length;
  final repaintKey = GlobalKey();

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Share progress story'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: repaintKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(dialogContext).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(dialogContext).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Dual N-Back Pro',
                      style: Theme.of(dialogContext).textTheme.labelMedium?.copyWith(
                            color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'I\'ve trained for $totalDays days',
                      style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Reached N=$highestN · ${(avgAcc * 100).round()}% accuracy',
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                    if (streak > 0)
                      Text(
                        '$streak day streak',
                        style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                              color: Theme.of(dialogContext).colorScheme.primary,
                            ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                if (boundary == null) return;
                final image = await boundary.toImage(pixelRatio: 2.0);
                final byteData = await image.toByteData(format: ImageByteFormat.png);
                if (byteData == null) return;
                final tempDir = await getTemporaryDirectory();
                final file = File('${tempDir.path}/progress_story_${DateTime.now().millisecondsSinceEpoch}.png');
                await file.writeAsBytes(byteData.buffer.asUint8List());
                try {
                  await Share.shareXFiles([XFile(file.path)], text: 'My Dual N-Back progress');
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                } on MissingPluginException catch (_) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Share is not available on this device.')),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Share failed: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.share),
              label: const Text('Share as image'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

/// Two lines: audio and visual accuracy over last sessions.
class _DualChannelChart extends StatelessWidget {
  const _DualChannelChart({required this.sessions});

  final List<SessionResult> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final audioSpots = sessions
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value.effectiveAudioAccuracy * 100)))
        .toList();
    final visualSpots = sessions
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value.effectiveVisualAccuracy * 100)))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        minY: 0,
        maxY: 100,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= 0 && i < sessions.length) {
                    final step = (sessions.length / 4).ceil().clamp(1, sessions.length);
                    if (i % step == 0 || i == sessions.length - 1) {
                      return Text(
                        DateFormat.Md().format(sessions[i].date),
                        style: const TextStyle(fontSize: 9),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: audioSpots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: visualSpots,
            isCurved: true,
            color: theme.colorScheme.secondary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

/// Grid: rows = day of week, columns = N-level, color = avg accuracy.
class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({required this.heatmap});

  final Map<int, Map<int, double>> heatmap;

  static const List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    int maxN = 1;
    for (final row in heatmap.values) {
      for (final n in row.keys) {
        if (n > maxN) maxN = n;
      }
    }
    maxN = maxN.clamp(1, 15);
    double maxAcc = 0.0;
    for (final row in heatmap.values) {
      for (final acc in row.values) {
        if (acc > maxAcc) maxAcc = acc;
      }
    }
    if (maxAcc <= 0) maxAcc = 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 36),
            ...List.generate(maxN, (i) => SizedBox(
                  width: 20,
                  child: Center(
                    child: Text('${i + 1}', style: theme.textTheme.labelSmall),
                  ),
                )),
          ],
        ),
        const SizedBox(height: 4),
        ...List.generate(7, (d) {
          final day = d + 1;
          final row = heatmap[day] ?? <int, double>{};
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(_dayLabels[d], style: theme.textTheme.labelSmall),
                ),
                ...List.generate(maxN, (n) {
                  final nLevel = n + 1;
                  final acc = row[nLevel] ?? 0.0;
                  final t = maxAcc > 0 ? (acc / maxAcc) : 0.0;
                  return Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2 + 0.8 * t),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: acc > 0
                        ? Center(
                            child: Text(
                              '${(acc * 100).round()}',
                              style: theme.textTheme.labelSmall?.copyWith(fontSize: 8),
                            ),
                          )
                        : null,
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem({
    required this.label,
    required this.value,
    required this.emphasis,
    this.leadingIcon,
  });

  final String label;
  final String value;
  final bool emphasis;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = (emphasis
            ? theme.textTheme.titleLarge
            : theme.textTheme.titleMedium)
        ?.copyWith(fontWeight: FontWeight.bold);
    final valueWidget = Text(value, style: valueStyle);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  leadingIcon,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                valueWidget,
              ],
            ),
          )
        else
          valueWidget,
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _NLevelChart extends StatelessWidget {
  const _NLevelChart({required this.sessions});

  final List<SessionResult> sessions;

  @override
  Widget build(BuildContext context) {
    final last30 = sessions.take(30).toList().reversed.toList();
    if (last30.isEmpty) return const SizedBox.shrink();

    final spots = last30
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.nLevel.toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i >= 0 && i < last30.length) {
                  return Text(
                    DateFormat.Md().format(last30[i].date),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final SessionResult session;

  static Widget _verticalDivider(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: theme.colorScheme.outline.withValues(alpha: 0.3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat.yMd().format(session.date);
    final accuracyStr = '${(session.accuracy * 100).round()}%';
    final hasChannel = session.audioAccuracy != null || session.visualAccuracy != null;
    final accuracySuffix = hasChannel
        ? '  (${(session.effectiveAudioAccuracy * 100).round()}% A | ${(session.effectiveVisualAccuracy * 100).round()}% V)'
        : '';

    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'N=${session.nLevel}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            _verticalDivider(context),
            Text(dateStr, style: bodyStyle),
            _verticalDivider(context),
            Expanded(
              child: Text(
                accuracyStr + accuracySuffix,
                style: bodyStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(
          height: 1,
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ],
    );
  }
}
