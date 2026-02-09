import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/settings_constants.dart';
import '../../../data/models/user_settings.dart';
import '../../../debug/simulator_runner.dart';
import '../../../logic/providers/game_provider.dart';
import '../../../logic/providers/settings_provider.dart';

/// Debug-only screen to start the simulator suite. Only reachable when [kDebugMode] is true.
class SimulatorDebugScreen extends ConsumerStatefulWidget {
  const SimulatorDebugScreen({super.key});

  @override
  ConsumerState<SimulatorDebugScreen> createState() =>
      _SimulatorDebugScreenState();
}

class _SimulatorDebugScreenState extends ConsumerState<SimulatorDebugScreen> {
  late final TextEditingController _runLengthController;
  late final TextEditingController _nLevelController;
  late final TextEditingController _kController;
  final Set<double> _selectedSpeeds = {};
  bool _isAutoN = true;

  @override
  void initState() {
    super.initState();
    _runLengthController = TextEditingController(text: '');
    _nLevelController = TextEditingController(text: '1');
    _kController = TextEditingController(text: '10');
    _selectedSpeeds.addAll(speedOptions);
  }

  @override
  void dispose() {
    _runLengthController.dispose();
    _nLevelController.dispose();
    _kController.dispose();
    super.dispose();
  }

  Future<void> _startSuite() async {
    if (!kDebugMode) return;
    final runLength = int.tryParse(_runLengthController.text.trim());
    final trialsPerSession =
        (runLength != null && runLength > 0) ? runLength : null;

    final speeds = _selectedSpeeds.isEmpty
        ? List<double>.from(speedOptions)
        : _selectedSpeeds.toList()..sort();

    int? nLevel;
    if (!_isAutoN) {
      final n = int.tryParse(_nLevelController.text.trim()) ?? 1;
      nLevel = n.clamp(1, 14);
    }

    final k = int.tryParse(_kController.text) ?? 10;
    final chainLength = k.clamp(1, 50);

    final runner = ref.read(simulatorRunnerProvider.notifier);
    runner.startSuite(
      speeds: speeds,
      isAutoN: _isAutoN,
      nLevel: nLevel,
      trialsPerSession: trialsPerSession,
      autoNChainLength: chainLength,
    );

    final config = runner.getFirstConfig();
    if (config == null) return;

    final runnerState = ref.read(simulatorRunnerProvider);
    final currentSettings = ref.read(settingsProvider).valueOrNull;
    if (currentSettings != null) {
      final updated = UserSettings(
        selectedThemeId: currentSettings.selectedThemeId,
        isAutoN: config.isAutoN,
        manualN: config.n.clamp(1, 14),
        continuousFeedback: currentSettings.continuousFeedback,
        focusMusicEnabled: currentSettings.focusMusicEnabled,
        reminderTime: currentSettings.reminderTime,
        speedMultiplier: config.speed,
        showGrid: currentSettings.showGrid,
        tapSoundEnabled: currentSettings.tapSoundEnabled,
        positionLeftAudioRight: currentSettings.positionLeftAudioRight,
      );
      await ref.read(settingsProvider.notifier).saveSettings(updated);
    }
    ref.read(currentNProvider.notifier).state = config.n;
    ref.read(gameSessionProvider.notifier).startSession(
          config.n,
          trialsPerSession: runnerState.trialsPerSession,
        );
    if (!mounted) return;
    // Dismiss keyboard before navigation to avoid IME hide animation timeout on Android.
    FocusScope.of(context).unfocus();
    if (!mounted) return;
    context.go('/game');
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final state = ref.watch(simulatorRunnerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulator (Debug)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                'Run simulator with selected options. Each session auto-submits 100% correct. '
                'Logs written to simulator_runs.json.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              // Run length per session
              Text(
                'Run length per session (trials)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _runLengthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Empty = use 20 + N',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              // Speed selection
              Text(
                'Speed(s)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: speedOptions.map((speed) {
                  final selected = _selectedSpeeds.contains(speed);
                  return FilterChip(
                    label: Text('$speed'),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedSpeeds.add(speed);
                        } else {
                          _selectedSpeeds.remove(speed);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Mode: My N / Auto N
              Text(
                'Mode',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('My N'),
                    icon: Icon(Icons.tag),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Auto N'),
                    icon: Icon(Icons.trending_up),
                  ),
                ],
                selected: {_isAutoN},
                onSelectionChanged: (Set<bool> selected) {
                  setState(() => _isAutoN = selected.first);
                },
              ),
              const SizedBox(height: 16),
              if (!_isAutoN) ...[
                Text(
                  'N level (1–14)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _nLevelController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '1',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
              ],
              if (_isAutoN) ...[
                Text(
                  'Auto N: sessions per speed (K)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _kController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '10',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Text(
                  'N changes based on accuracy (70%+ ↑, <70% ↓).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: state.isActive
                    ? null
                    : (_selectedSpeeds.isEmpty ? null : _startSuite),
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  _isAutoN
                      ? 'Run Auto N suite'
                      : 'Run My N suite',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (state.isActive)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Suite running: ${state.completedRuns}/${state.totalRuns}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
