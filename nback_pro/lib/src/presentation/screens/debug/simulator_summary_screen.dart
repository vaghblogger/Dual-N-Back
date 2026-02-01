import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/settings_constants.dart';
import '../../../debug/simulator_runner.dart';
import '../../../logic/providers/game_provider.dart';

/// Debug-only screen showing simulator suite summary (My N + Auto N by speed).
/// Only build when [kDebugMode]; if not debug or logs empty, redirect to home.
class SimulatorSummaryScreen extends ConsumerWidget {
  const SimulatorSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final state = ref.watch(simulatorRunnerProvider);
    if (state.logs.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final myNBySpeed = _groupBySpeed(state.logs.where((e) => e.mode == 'MyN'));
    final autoNBySpeed =
        _groupBySpeed(state.logs.where((e) => e.mode == 'AutoN'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulator summary'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Suite complete: ${state.logs.length} runs.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              _sectionHeader(context, 'My N'),
              ...speedOptions.map((speed) {
                final group = myNBySpeed[speed];
                if (group == null || group.isEmpty) return const SizedBox.shrink();
                return _speedCard(
                  context,
                  speed: speed,
                  runCount: group.length,
                  avgDurationMs: group.fold<int>(0, (s, e) => s + e.durationMs) ~/
                      group.length,
                  nRange: null,
                  allPerfect: group.every((e) => e.totalAccuracy >= 1.0),
                );
              }),
              const SizedBox(height: 16),
              _sectionHeader(context, 'Auto N'),
              ...speedOptions.map((speed) {
                final group = autoNBySpeed[speed];
                if (group == null || group.isEmpty) return const SizedBox.shrink();
                final minN = group.map((e) => e.nLevel).reduce((a, b) => a < b ? a : b);
                final maxN = group
                    .map((e) => e.nLevelAfter ?? e.nLevel)
                    .reduce((a, b) => a > b ? a : b);
                final avgMs = group.fold<int>(0, (s, e) => s + e.durationMs) ~/
                    group.length;
                return _speedCard(
                  context,
                  speed: speed,
                  runCount: group.length,
                  avgDurationMs: avgMs,
                  nRange: 'N $minN → N $maxN',
                  allPerfect: null,
                );
              }),
              if (state.lastExportPath != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Log file: ${state.lastExportPath}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Home'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _viewLastRun(context, ref, state.logs),
                child: const Text('View last run'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _speedCard(
    BuildContext context, {
    required double speed,
    required int runCount,
    required int avgDurationMs,
    String? nRange,
    bool? allPerfect,
  }) {
    final avgSec = (avgDurationMs / 1000).toStringAsFixed(1);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Speed $speed'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$runCount runs, avg ${avgSec}s'),
            if (nRange != null) Text(nRange),
            if (allPerfect == true)
              Text(
                'All 100% accuracy',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  void _viewLastRun(
      BuildContext context, WidgetRef ref, List<SimulatorLogEntry> logs) {
    if (logs.isEmpty) return;
    final last = logs.last;
    ref.read(lastSessionSummaryProvider.notifier).state = SessionSummaryData(
      nLevel: last.nLevel,
      audioScore: last.audioScore,
      visualScore: last.visualScore,
      totalAccuracy: last.totalAccuracy,
      newN: last.nLevelAfter ?? last.nLevel,
      isAutoN: last.mode == 'AutoN',
    );
    context.go('/session-summary');
  }
}

Map<double, List<SimulatorLogEntry>> _groupBySpeed(
    Iterable<SimulatorLogEntry> entries) {
  final map = <double, List<SimulatorLogEntry>>{};
  for (final e in entries) {
    map.putIfAbsent(e.speed, () => []).add(e);
  }
  return map;
}
