import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/settings_constants.dart';
import '../../../logic/providers/game_provider.dart';
import '../../../logic/providers/settings_provider.dart';
import '../../../logic/providers/stats_provider.dart';
import '../../../logic/providers/subscription_provider.dart';
import '../../widgets/paywall_dialog.dart';

/// Screen to pick N (1–15), speed, and grid for a single session and start the game.
/// Session options default to stored settings and apply only for this session.
class TrainScreen extends ConsumerStatefulWidget {
  const TrainScreen({super.key});

  @override
  ConsumerState<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends ConsumerState<TrainScreen> {
  static const int _minN = 1;
  static const int _maxN = 15;
  static const int _freeMaxN = 3;
  static const int _freeSessionsPerDay = 2;

  int _selectedN = 1;
  double _sessionSpeed = 1.0;
  bool _sessionShowGrid = false;
  bool _initializedFromSettings = false;
  bool _nInitialized = false;

  Future<void> _onStartTapped() async {
    final isPremium = ref.read(isPremiumProvider);
    final settings = ref.read(settingsProvider).valueOrNull;
    final isAutoN = isPremium ? (settings?.isAutoN ?? true) : true;
    final nToUse = isAutoN ? _selectedN : (settings?.manualN ?? 1).clamp(_minN, isPremium ? _maxN : _freeMaxN);
    if (!isPremium && nToUse >= 4) {
      showPaywallDialog(
        context,
        paywallContext: PaywallContext.train,
      );
      return;
    }
    if (!isPremium) {
      final sessionsToday = await ref.read(sessionsCompletedTodayProvider.future);
      if (!mounted) return;
      if (sessionsToday >= _freeSessionsPerDay) {
        showPaywallDialogSessionLimit(context, onDismiss: () {});
        return;
      }
    }
    _startSession();
  }

  void _startSession() {
    final settings = ref.read(settingsProvider).valueOrNull;
    final isPremium = ref.read(isPremiumProvider);
    final isAutoN = isPremium ? (settings?.isAutoN ?? true) : true;
    final nToUse = isAutoN ? _selectedN : (settings?.manualN ?? 1).clamp(_minN, isPremium ? _maxN : _freeMaxN);
    ref.read(sessionOverridesProvider.notifier).state = SessionOverrides(
      speedMultiplier: _sessionSpeed,
      showGrid: _sessionShowGrid,
    );
    ref.read(currentNProvider.notifier).state = nToUse;
    context.go('/pre-game', extra: {'n': nToUse});
  }

  int _speedIndex(double v) {
    int best = 0;
    for (int i = 0; i < speedOptions.length; i++) {
      if ((speedOptions[i] - v).abs() < (speedOptions[best] - v).abs()) {
        best = i;
      }
    }
    return best;
  }

  String _speedLabel(double v) {
    return v == v.truncateToDouble() ? '${v.toInt()}x' : '${v}x';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(isPremiumProvider);
    final maxNForUser = isPremium ? _maxN : _freeMaxN;
    final highestNAsync = ref.watch(highestNProvider);
    final highestN = highestNAsync.valueOrNull ?? 0;
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings != null && !_initializedFromSettings) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _sessionSpeed = settings.speedMultiplier;
            _sessionShowGrid = settings.showGrid;
            _initializedFromSettings = true;
          });
        }
      });
    }
    final isAutoN = isPremium ? (settings?.isAutoN ?? true) : true;
    final manualN = (settings?.manualN ?? 1).clamp(_minN, isPremium ? _maxN : _freeMaxN);
    if (!_nInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final s = ref.read(settingsProvider).valueOrNull;
        final autoN = isPremium ? (s?.isAutoN ?? true) : true;
        final maxNForUser = isPremium ? _maxN : _freeMaxN;
        if (!autoN && s != null) {
          setState(() {
            _selectedN = (s.manualN).clamp(_minN, maxNForUser);
            _nInitialized = true;
          });
          return;
        }
        final highestN = await ref.read(highestNProvider.future);
        if (!mounted) return;
        final defaultN = (highestN + 1).clamp(_minN, maxNForUser);
        if (!mounted) return;
        setState(() {
          _selectedN = defaultN;
          _nInitialized = true;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          AppStrings.trainYourBrain,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            iconSize: 28,
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                AppStrings.currentNLevelDisplay.replaceAll('%d', '$highestN'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Text(
                AppStrings.nextNLevel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (settings != null && isPremium && settings.isAutoN) ...[
                const SizedBox(height: 4),
                Text(
                  AppStrings.autoNAdjustAfterThisSession,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (settings != null && isPremium && !settings.isAutoN) ...[
                const SizedBox(height: 4),
                Text(
                  AppStrings.proTrainingMyNMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    icon: const Icon(Icons.remove),
                    iconSize: 32,
                    onPressed: isAutoN && _selectedN > _minN
                        ? () => setState(() => _selectedN--)
                        : null,
                  ),
                  const SizedBox(width: 24),
                  Text(
                    'N = ${isAutoN ? _selectedN : manualN}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isAutoN ? null : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    iconSize: 32,
                    onPressed: isAutoN
                        ? () {
                            if (_selectedN < maxNForUser) {
                              setState(() => _selectedN++);
                            } else if (!isPremium && _selectedN == _freeMaxN) {
                              showPaywallDialog(
                                context,
                                paywallContext: PaywallContext.train,
                              );
                            }
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.speed,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              ListTile(
                title: Text(_speedLabel(_sessionSpeed)),
                subtitle: Slider(
                  value: _speedIndex(_sessionSpeed).toDouble(),
                  min: 0,
                  max: (speedOptions.length - 1).toDouble(),
                  divisions: speedOptions.length - 1,
                  label: _speedLabel(_sessionSpeed),
                  onChanged: (v) {
                    setState(() {
                      _sessionSpeed = speedOptions[v.round()];
                    });
                  },
                ),
              ),
              if (_sessionSpeed < 1.0) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 4),
                  child: Text(
                    AppStrings.speedBelowOneNudge,
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text(AppStrings.showGrid),
                subtitle: const Text(AppStrings.showGridSubtitle),
                value: _sessionShowGrid,
                onChanged: (value) => setState(() => _sessionShowGrid = value),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _onStartTapped,
                  style: FilledButton.styleFrom(
                    textStyle: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text(AppStrings.go),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
