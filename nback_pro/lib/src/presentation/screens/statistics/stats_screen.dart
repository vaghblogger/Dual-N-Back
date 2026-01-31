import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/models/session_result.dart';
import '../../../logic/providers/stats_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(allSessionsProvider);
    final averageNAsync = ref.watch(averageNProvider);
    final streakAsync = ref.watch(currentStreakProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(AppStrings.yourProgress),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sessions) {
          final averageN = averageNAsync.valueOrNull ?? 0.0;
          final streak = streakAsync.valueOrNull ?? 0;
          final maxN = sessions.isEmpty
              ? 0
              : sessions.map((s) => s.nLevel).reduce((a, b) => a > b ? a : b);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: AppStrings.averageNLevel,
                        value: averageN.toStringAsFixed(1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: AppStrings.currentNLevel,
                        value: '$maxN',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: AppStrings.totalSessions,
                        value: '${sessions.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: AppStrings.currentStreak,
                        value: '$streak',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (sessions.isNotEmpty) ...[
                  Text(
                    'N-Level (last 30 days)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: _NLevelChart(sessions: sessions),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  AppStrings.sessionHistory,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...sessions.take(20).map((s) => _SessionTile(session: s)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('N=${session.nLevel}'),
      subtitle: Text(
        '${DateFormat.yMd().format(session.date)} · ${(session.accuracy * 100).round()}%',
      ),
    );
  }
}
