import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/settings_constants.dart';
import '../../../logic/providers/settings_provider.dart';
import '../onboarding/theme_selection_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(AppStrings.settings),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text(AppStrings.dailyReminder),
              subtitle: Text(settings.reminderTime ?? 'Not set'),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null && context.mounted) {
                  final iso = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  await ref.read(settingsProvider.notifier).setReminderTime(iso);
                }
              },
            ),
            SwitchListTile(
              title: const Text(AppStrings.autoN),
              value: settings.isAutoN,
              onChanged: (_) =>
                  ref.read(settingsProvider.notifier).toggleAutoN(),
            ),
            ListTile(
              title: const Text(AppStrings.myN),
              enabled: !settings.isAutoN,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: !settings.isAutoN && settings.manualN > 1
                        ? () => ref.read(settingsProvider.notifier).setManualN(settings.manualN - 1)
                        : null,
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${settings.manualN}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: !settings.isAutoN && settings.manualN < 15
                        ? () => ref.read(settingsProvider.notifier).setManualN(settings.manualN + 1)
                        : null,
                  ),
                ],
              ),
            ),
            SliderListTile(
              title: AppStrings.speed,
              value: _speedIndex(settings.speedMultiplier).toDouble(),
              min: 0,
              max: 6,
              divisions: 6,
              label: _speedLabel(speedOptions[_speedIndex(settings.speedMultiplier)]),
              onChanged: (v) {
                final speed = speedOptions[v.round()];
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
            SwitchListTile(
              title: const Text(AppStrings.continuousFeedback),
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
            SwitchListTile(
              title: const Text(AppStrings.focusMusic),
              value: settings.focusMusicEnabled,
              onChanged: (value) =>
                  ref.read(settingsProvider.notifier).setFocusMusicEnabled(value),
            ),
            ListTile(
              title: const Text(AppStrings.theme),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ThemeSelectionScreen(fromSettings: true),
                ),
              ),
            ),
            ListTile(
              title: const Text(AppStrings.giveFeedback),
              onTap: () => launchUrl(Uri.parse('mailto:feedback@example.com')),
            ),
            ListTile(
              title: const Text(AppStrings.privacyPolicy),
              onTap: () => launchUrl(Uri.parse('https://example.com/privacy')),
            ),
            ListTile(
              title: const Text(AppStrings.termsOfUse),
              onTap: () => launchUrl(Uri.parse('https://example.com/terms')),
            ),
          ],
        ),
      ),
    );
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
    return v == v.truncateToDouble()
        ? '${v.toInt()}x'
        : '${v}x';
  }

  void _showWarning(BuildContext context, String title, String message) {
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
}

class SliderListTile extends StatelessWidget {
  const SliderListTile({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    this.label,
    this.enabled = true,
    this.onChanged,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String? label;
  final bool enabled;
  final void Function(double)? onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: label ?? value.toStringAsFixed(1),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
