import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/settings_constants.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../logic/providers/settings_provider.dart';
import '../../widgets/setting_card.dart';

/// Spacing between setting cards.
const double _cardSpacing = 8;

/// Advanced settings screen: card per option with small-font description.
/// Only Settings UI; no game flow changes.
class AdvancedSettingsScreen extends ConsumerWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    const maxN = 14;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(AppStrings.advancedSettings),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) {
          return ListView(
            padding: EdgeInsets.fromLTRB(
              ResponsiveLayout.horizontalPadding(context),
              16,
              ResponsiveLayout.horizontalPadding(context),
              ResponsiveLayout.horizontalPadding(context),
            ),
            children: [
              SettingCard(
                title: AppStrings.autoN,
                subtitle: AppStrings.autoNSubtitle,
                trailing: Switch(
                  value: settings.isAutoN,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).setAutoN(value),
                ),
              ),
              const SizedBox(height: _cardSpacing),
              // When Auto N is ON, My N is OFF (disabled and not editable).
              Opacity(
                opacity: settings.isAutoN ? 0.6 : 1,
                child: IgnorePointer(
                  ignoring: settings.isAutoN,
                  child: SettingCard(
                    title: AppStrings.myN,
                    subtitle: settings.isAutoN
                        ? AppStrings.myNDisabledSubtitle
                        : 'Choose N from 1 to $maxN (match that many steps back).',
                    child: _NLevelSegmented(
                      value: settings.manualN.clamp(1, maxN),
                      maxN: maxN,
                      onChanged: settings.isAutoN
                          ? null
                          : (n) =>
                                ref.read(settingsProvider.notifier).setManualN(n),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _cardSpacing),
              SettingCard(
                title: AppStrings.instantFeedback,
                subtitle: AppStrings.instantFeedbackSubtitle,
                trailing: Switch(
                  value: settings.continuousFeedback,
                  onChanged: (value) {
                    if (value) {
                      _showWarning(
                        context,
                        AppStrings.feedbackWarningTitle,
                        AppStrings.feedbackWarningMessage,
                      );
                    }
                    ref.read(settingsProvider.notifier).setContinuousFeedback(value);
                  },
                ),
              ),
              const SizedBox(height: _cardSpacing),
              SettingCard(
                title: AppStrings.buttonPositions,
                subtitle: AppStrings.buttonPositionsSubtitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: settings.positionLeftAudioRight,
                          onChanged: (value) {
                            if (value == true) {
                              ref.read(settingsProvider.notifier).setPositionLeftAudioRight(true);
                            }
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                ref.read(settingsProvider.notifier).setPositionLeftAudioRight(true),
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              AppStrings.positionLeftSoundRight,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: settings.positionLeftAudioRight,
                          onChanged: (value) {
                            if (value == false) {
                              ref.read(settingsProvider.notifier).setPositionLeftAudioRight(false);
                            }
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                ref.read(settingsProvider.notifier).setPositionLeftAudioRight(false),
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              AppStrings.soundLeftPositionRight,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _cardSpacing),
              SettingCard(
                title: AppStrings.showGrid,
                subtitle: AppStrings.showGridSubtitle,
                trailing: Switch(
                  value: settings.showGrid,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).setShowGrid(value),
                ),
              ),
              const SizedBox(height: _cardSpacing),
              SettingCard(
                title: AppStrings.tapSound,
                subtitle: AppStrings.tapSoundSubtitle,
                trailing: Switch(
                  value: settings.tapSoundEnabled,
                  onChanged: (value) =>
                      ref.read(settingsProvider.notifier).setTapSoundEnabled(value),
                ),
              ),
              const SizedBox(height: _cardSpacing),
              SettingCard(
                title: AppStrings.speed,
                subtitle: AppStrings.speedDefaultMessage,
                child: _SpeedSlider(
                  speedMultiplier: settings.speedMultiplier,
                  onChanged: (speed) {
                    if (speed < 1.0) {
                      _showWarning(
                        context,
                        AppStrings.speedWarningTitle,
                        AppStrings.speedWarningMessage,
                      );
                    }
                    ref.read(settingsProvider.notifier).setSpeedMultiplier(speed);
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _resetScientificDefaults(context, ref),
                  child: const Text(AppStrings.resetScientificDefaults),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  static void _showWarning(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetScientificDefaults(BuildContext context, WidgetRef ref) async {
    await ref.read(settingsProvider.notifier).resetScientificDefaults();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.scientificDefaultsRestored)),
    );
  }
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

class _SpeedSlider extends StatelessWidget {
  const _SpeedSlider({
    required this.speedMultiplier,
    required this.onChanged,
  });

  final double speedMultiplier;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    final index = _speedIndex(speedMultiplier).toDouble();
    final label = speedMultiplier == speedMultiplier.truncateToDouble()
        ? '${speedMultiplier.toInt()}x'
        : '${speedMultiplier}x';
    return Slider(
      value: index.clamp(0, 6),
      min: 0,
      max: 6,
      divisions: 6,
      label: label,
      onChanged: (v) => onChanged(speedOptions[v.round()]),
    );
  }
}

const int _myNColumns = 7;
const double _myNSpacing = 8;

class _NLevelSegmented extends StatelessWidget {
  const _NLevelSegmented({
    required this.value,
    required this.maxN,
    this.onChanged,
  });

  final int value;
  final int maxN;
  final void Function(int)? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levels = List.generate(maxN, (i) => i + 1);
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _myNColumns,
        mainAxisSpacing: _myNSpacing,
        crossAxisSpacing: _myNSpacing,
        childAspectRatio: 1,
      ),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final n = levels[index];
        return _MyNBox(
          n: n,
          selected: n == value,
          theme: theme,
          onTap: onChanged != null ? () => onChanged!(n) : null,
        );
      },
    );
  }
}

class _MyNBox extends StatelessWidget {
  const _MyNBox({
    required this.n,
    required this.selected,
    required this.theme,
    this.onTap,
  });

  final int n;
  final bool selected;
  final ThemeData theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            '$n',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
