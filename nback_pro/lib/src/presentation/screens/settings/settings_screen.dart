import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/settings_constants.dart';
import '../../../data/models/subscription_state.dart';
import '../../../data/services/app_reset_service.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/onboarding_provider.dart';
import '../../../logic/providers/settings_provider.dart';
import '../../../logic/providers/stats_provider.dart';
import '../../../logic/providers/subscription_provider.dart';
import '../onboarding/theme_selection_screen.dart';
import '../../widgets/paywall_dialog.dart';

const String _keyPremiumAutoNDefaultApplied = 'premium_auto_n_default_applied';
bool _premiumAutoNMigrationScheduled = false;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsProvider);
    ref.watch(isPremiumProvider);
    // One-time per app run: when premium and Auto N is off, set it to ON (premium default).
    if (!_premiumAutoNMigrationScheduled) {
      _premiumAutoNMigrationScheduled = true;
      Future.microtask(() async {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool(_keyPremiumAutoNDefaultApplied) == true) return;
        final isPremium = ref.read(isPremiumProvider);
        final settings = ref.read(settingsProvider).valueOrNull;
        if (!isPremium || settings == null || settings.isAutoN) return;
        await ref.read(settingsProvider.notifier).setAutoN(true);
        await prefs.setBool(_keyPremiumAutoNDefaultApplied, true);
      });
    }

    final settingsAsync = ref.watch(settingsProvider);
    final currentUser = ref.watch(currentUserProvider);

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
        data: (settings) {
          final isPremium = ref.watch(isPremiumProvider);
          final maxManualN = isPremium ? 15 : 1;
          final effectiveManualN =
              isPremium ? settings.manualN : 1;
          final isLoggedIn = currentUser != null;
          final user = currentUser;
          final accountSubtitle = isLoggedIn && user != null
              ? (user.email ?? user.displayName ?? 'Signed in')
              : AppStrings.loginToSaveProgress;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: InkWell(
                  onTap: () {
                    if (!isLoggedIn) {
                      context.go('/login?from=settings');
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isLoggedIn
                                    ? AppStrings.account
                                    : AppStrings.notLoggedIn,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isLoggedIn)
                              TextButton(
                                onPressed: () => _signOut(context, ref),
                                child: Text(AppStrings.signOut),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          accountSubtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (!isPremium) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.block,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            AppStrings.adFree,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              AppStrings.settingsAdFree,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => showPaywallDialog(
                                  context,
                                  paywallContext: PaywallContext.progress,
                                ),
                            icon: const Icon(Icons.workspace_premium, size: 20),
                            label: const Text(AppStrings.goPro),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              ListTile(
                title: const Text(AppStrings.dailyReminder),
                trailing: Text(
                  settings.reminderTime ?? 'Not set',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
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
              value: isPremium ? settings.isAutoN : true,
              onChanged: isPremium
                  ? (_) =>
                      ref.read(settingsProvider.notifier).toggleAutoN()
                  : null,
              subtitle: isPremium
                  ? Text(
                      'Adjusts N by performance. Turn off to use My N.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : Text(
                      'Unlock Pro to choose Auto N or My N.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
            ),
            ListTile(
              title: const Text(AppStrings.myN),
              subtitle: const Text(AppStrings.myNSubtitle),
              enabled: true,
              trailing: isPremium
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: !settings.isAutoN && effectiveManualN > 1
                              ? () => ref.read(settingsProvider.notifier).setManualN(
                                  (effectiveManualN - 1).clamp(1, maxManualN))
                              : null,
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(
                            'N = $effectiveManualN',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: !settings.isAutoN && effectiveManualN < maxManualN
                              ? () => ref.read(settingsProvider.notifier).setManualN(
                                  (effectiveManualN + 1).clamp(1, maxManualN))
                              : null,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          'N = $effectiveManualN',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
              onTap: !isPremium
                  ? () => showPaywallDialog(context, paywallContext: PaywallContext.progress)
                  : null,
            ),
            Builder(
              builder: (context) {
                if (!isPremium) {
                  return ListTile(
                    title: const Text(AppStrings.speed),
                    subtitle: Text(
                      AppStrings.speedDefaultMessage,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Icon(Icons.lock, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    onTap: () => showPaywallDialog(context, paywallContext: PaywallContext.progress),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Text(
                        AppStrings.speedDefaultMessage,
                        style: Theme.of(context).textTheme.bodySmall,
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
                  ],
                );
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
              title: const Text(AppStrings.showGrid),
              subtitle: const Text(AppStrings.showGridSubtitle),
              value: settings.showGrid,
              onChanged: (value) =>
                  ref.read(settingsProvider.notifier).setShowGrid(value),
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
              onTap: () => launchUrl(Uri.parse('mailto:${AppStrings.feedbackEmail}')),
            ),
            ListTile(
              title: const Text(AppStrings.privacyPolicy),
              onTap: () => launchUrl(Uri.parse(AppStrings.privacyPolicyUrl)),
            ),
            ListTile(
              title: const Text(AppStrings.termsOfUse),
              onTap: () => launchUrl(Uri.parse(AppStrings.termsOfUseUrl)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.restart_alt, color: Theme.of(context).colorScheme.error),
              title: Text(
                'Reset app & data',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Clear all data and return to first-run experience (for testing new installation)',
              ),
              onTap: () => _showResetConfirmation(context, ref),
            ),
            const SizedBox(height: 8),
            _VersionTapTile(),
          ],
        );
      },
    ),
  );
}

  static Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
    await setGuest(true);
    if (!context.mounted) return;
    ref.invalidate(authStateChangesProvider);
    ref.invalidate(isGuestProvider);
    ref.invalidate(onboardingCompleteProvider);
    ref.invalidate(settingsProvider);
    ref.invalidate(allSessionsProvider);
    ref.invalidate(averageNProvider);
    ref.invalidate(highestNProvider);
    ref.invalidate(currentStreakProvider);
    ref.invalidate(streakDataProvider);
    ref.invalidate(isChallengeCompleteTodayProvider);
    ref.invalidate(daysTrainedInLast7DaysProvider);
    ref.invalidate(last7DaysCompletedProvider);
    context.go('/login');
  }

  static Future<void> _showResetConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset app & data?'),
        content: const Text(
          'This will delete all settings, session history, streaks, and sign you out. '
          'You will see the app as if it were a fresh installation. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await resetApp(ref);
    if (!context.mounted) return;
    context.go('/');
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

/// Version row; in debug builds, tap 7 times to cycle dev subscription override.
class _VersionTapTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_VersionTapTile> createState() => _VersionTapTileState();
}

class _VersionTapTileState extends ConsumerState<_VersionTapTile> {
  int _tapCount = 0;
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(_version.isEmpty ? 'Version' : 'Version $_version'),
      onTap: kDebugMode ? _onTap : null,
    );
  }

  void _onTap() {
    setState(() => _tapCount++);
    if (_tapCount >= 7) {
      _tapCount = 0;
      _showDevOverrideDialog();
    }
  }

  void _showDevOverrideDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dev: Subscription override'),
        content: const Text(
          'Set effective subscription state for testing. Disabled in release.',
        ),
        actions: [
          TextButton(
            onPressed: () => _setOverride(null),
            child: const Text('Real state'),
          ),
          TextButton(
            onPressed: () => _setOverride(SubscriptionState.free),
            child: const Text('FREE'),
          ),
          TextButton(
            onPressed: () => _setOverride(SubscriptionState.premiumActive),
            child: const Text('PREMIUM'),
          ),
          TextButton(
            onPressed: () => _setOverride(SubscriptionState.premiumExpired),
            child: const Text('EXPIRED'),
          ),
        ],
      ),
    );
  }

  void _setOverride(SubscriptionState? value) {
    ref.read(devSubscriptionOverrideProvider.notifier).state = value;
    if (context.mounted) Navigator.of(context).pop();
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
