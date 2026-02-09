import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../logic/providers/game_provider.dart';

/// Per-run log entry for simulator suite.
class SimulatorLogEntry {
  final int runId;
  final String mode;
  final int nLevel;
  final int? nLevelAfter;
  final double speed;
  final int totalTrials;
  final int durationMs;
  final double audioScore;
  final double visualScore;
  final double totalAccuracy;
  final String timestamp;

  const SimulatorLogEntry({
    required this.runId,
    required this.mode,
    required this.nLevel,
    this.nLevelAfter,
    required this.speed,
    required this.totalTrials,
    required this.durationMs,
    required this.audioScore,
    required this.visualScore,
    required this.totalAccuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'run_id': runId,
        'mode': mode,
        'n_level': nLevel,
        if (nLevelAfter != null) 'n_level_after': nLevelAfter,
        'speed': speed,
        'total_trials': totalTrials,
        'duration_ms': durationMs,
        'audio_score': audioScore,
        'visual_score': visualScore,
        'total_accuracy': totalAccuracy,
        'timestamp': timestamp,
      };
}

/// One run config: n (null = use currentNProvider), speed, isAutoN.
class _RunConfig {
  final int? n;
  final double speed;
  final bool isAutoN;

  const _RunConfig({this.n, required this.speed, required this.isAutoN});
}

/// State for the simulator runner. Only active when suite is running.
class SimulatorRunnerState {
  final bool isActive;
  final int totalRuns;
  final int currentRunIndex;
  final List<SimulatorLogEntry> logs;
  /// Set when suite completes and exportLogs() succeeds; shown on summary screen.
  final String? lastExportPath;
  /// Override trials per session (null = use 20 + n). Set when suite starts.
  final int? trialsPerSession;

  const SimulatorRunnerState({
    this.isActive = false,
    this.totalRuns = 0,
    this.currentRunIndex = 0,
    this.logs = const [],
    this.lastExportPath,
    this.trialsPerSession,
  });

  int get completedRuns => logs.length;
}

class SimulatorRunnerNotifier extends StateNotifier<SimulatorRunnerState> {
  SimulatorRunnerNotifier(this._ref) : super(const SimulatorRunnerState());

  final Ref _ref;

  List<_RunConfig> _permutation = [];

  /// Builds permutation from options.
  /// [speeds]: which speed(s) to run (e.g. [1.0] or all speedOptions).
  /// [isAutoN]: true = Auto N (N changes by accuracy), false = My N (fixed N).
  /// [nLevel]: for My N, the fixed N (1–14). Ignored when isAutoN is true.
  /// [trialsPerSession]: override run length per session (null = use 20 + n).
  /// [autoNChainLength]: for Auto N, number of sessions per speed (N progression).
  void startSuite({
    required List<double> speeds,
    required bool isAutoN,
    int? nLevel,
    int? trialsPerSession,
    int autoNChainLength = 10,
  }) {
    if (!kDebugMode) return;
    final runs = <_RunConfig>[];
    if (isAutoN) {
      for (final speed in speeds) {
        runs.add(_RunConfig(n: 1, speed: speed, isAutoN: true));
        for (var k = 1; k < autoNChainLength; k++) {
          runs.add(_RunConfig(n: null, speed: speed, isAutoN: true));
        }
      }
    } else {
      final n = (nLevel ?? 1).clamp(1, 14);
      for (final speed in speeds) {
        runs.add(_RunConfig(n: n, speed: speed, isAutoN: false));
      }
    }
    _permutation = runs;
    state = SimulatorRunnerState(
      isActive: true,
      totalRuns: runs.length,
      currentRunIndex: 0,
      logs: [],
      trialsPerSession: trialsPerSession,
    );
  }

  /// Returns the config for the current run (index 0 after startSuite).
  /// Caller must apply settings and startSession(n ?? currentN).
  ({int n, double speed, bool isAutoN})? getCurrentConfig() {
    if (!state.isActive || _permutation.isEmpty) return null;
    if (state.currentRunIndex >= _permutation.length) return null;
    final config = _permutation[state.currentRunIndex];
    final int n = config.n ?? _ref.read(currentNProvider);
    return (n: n, speed: config.speed, isAutoN: config.isAutoN);
  }

  /// Call after applying settings and before navigating to /game for the first run.
  /// Returns the first run config so caller can apply and startSession.
  ({int n, double speed, bool isAutoN})? getFirstConfig() {
    return getCurrentConfig();
  }

  /// Records the completed run and advances to next. Returns next config or null if suite complete.
  /// For Auto N, [nLevelAfter] should be ref.read(currentNProvider) after persistSession.
  Future<({int n, double speed, bool isAutoN})?> recordRunAndPrepareNext(
    SimulatorLogEntry entry,
  ) async {
    if (!state.isActive) return null;
    state = SimulatorRunnerState(
      isActive: state.isActive,
      totalRuns: state.totalRuns,
      currentRunIndex: state.currentRunIndex + 1,
      logs: [...state.logs, entry],
    );
    if (state.currentRunIndex >= _permutation.length) {
      final path = await exportLogs();
      state = SimulatorRunnerState(
        isActive: false,
        totalRuns: state.totalRuns,
        currentRunIndex: state.currentRunIndex,
        logs: state.logs,
        lastExportPath: path,
        trialsPerSession: state.trialsPerSession,
      );
      return null;
    }
    return getCurrentConfig();
  }

  void stopSuite() {
    state = SimulatorRunnerState(
      isActive: false,
      totalRuns: state.totalRuns,
      currentRunIndex: state.currentRunIndex,
      logs: state.logs,
      lastExportPath: state.lastExportPath,
      trialsPerSession: state.trialsPerSession,
    );
  }

  /// Writes logs to simulator_runs.json in application documents directory.
  Future<String?> exportLogs() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/simulator_runs.json');
      final list = state.logs.map((e) => e.toJson()).toList();
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(list));
      return file.path;
    } catch (_) {
      return null;
    }
  }
}

final simulatorRunnerProvider =
    StateNotifierProvider<SimulatorRunnerNotifier, SimulatorRunnerState>((ref) {
  return SimulatorRunnerNotifier(ref);
});
