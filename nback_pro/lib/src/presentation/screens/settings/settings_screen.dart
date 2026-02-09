import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../data/models/subscription_state.dart';
import '../../../data/services/app_reset_service.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/notification_service_provider.dart';
import '../../../logic/providers/onboarding_provider.dart';
import '../../../logic/providers/settings_provider.dart';
import '../../../logic/providers/stats_provider.dart';
import '../../../logic/providers/subscription_provider.dart';
import '../onboarding/theme_selection_screen.dart';
import '../../widgets/paywall_dialog.dart';
import '../../widgets/setting_card.dart';

const String _keyPremiumAutoNDefaultApplied = 'premium_auto_n_default_applied';
bool _premiumAutoNMigrationScheduled = false;

const double _cardSpacing = 8;

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
          final isLoggedIn = currentUser != null;
          final user = currentUser;
          final accountSubtitle = isLoggedIn && user != null
              ? (user.email ?? user.displayName ?? 'Signed in')
              : AppStrings.loginToSaveProgress;
          final theme = Theme.of(context);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              ResponsiveLayout.horizontalPadding(context),
              16,
              ResponsiveLayout.horizontalPadding(context),
              ResponsiveLayout.horizontalPadding(context),
            ),
            children: [
              SettingCard(
                leading: Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.primary,
                ),
                title: isLoggedIn ? AppStrings.account : AppStrings.notLoggedIn,
                subtitle: accountSubtitle,
                trailing: isLoggedIn
                    ? TextButton(
                        onPressed: () => _signOut(context, ref),
                        child: Text(AppStrings.signOut),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: isLoggedIn ? null : () => context.go('/login?from=settings'),
              ),
              const SizedBox(height: _cardSpacing),
              if (!isPremium) ...[
                SettingCard(
                  leading: Icon(
                    Icons.workspace_premium,
                    color: theme.colorScheme.primary,
                  ),
                  title: AppStrings.adFree,
                  subtitle: AppStrings.settingsAdFree,
                  child: SizedBox(
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
                ),
                const SizedBox(height: _cardSpacing),
              ],
              SettingCard(
                title: AppStrings.dailyReminder,
                subtitle: AppStrings.dailyReminderSubtitle,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      settings.reminderTime ?? 'Not set',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null && context.mounted) {
                    final notificationService = ref.read(notificationServiceProvider);
                    await notificationService.requestPermissions();
                    if (!context.mounted) return;
                    final iso = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                    await ref.read(settingsProvider.notifier).setReminderTime(iso);
                  }
                },
              ),
              const SizedBox(height: _cardSpacing),
              SettingCard(
                title: AppStrings.advancedSettings,
                subtitle: AppStrings.advancedSettingsSubtitle,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/advanced'),
              ),
              const SizedBox(height: _cardSpacing),
              SettingCard(
                title: AppStrings.theme,
                subtitle: AppStrings.themeSubtitle,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ThemeSelectionScreen(fromSettings: true),
                  ),
                ),
              ),
              const SizedBox(height: _cardSpacing),
              SettingCard(
                title: AppStrings.giveFeedback,
                subtitle: AppStrings.giveFeedbackSubtitle,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => launchUrl(Uri.parse('mailto:${AppStrings.feedbackEmail}')),
              ),
              const SizedBox(height: _cardSpacing),
              SettingCard(
                title: AppStrings.privacyPolicy,
                subtitle: AppStrings.privacyPolicySubtitle,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => launchUrl(Uri.parse(AppStrings.privacyPolicyUrl)),
              ),
              const SizedBox(height: _cardSpacing),
              SettingCard(
                title: AppStrings.termsOfUse,
                subtitle: AppStrings.termsOfUseSubtitle,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => launchUrl(Uri.parse(AppStrings.termsOfUseUrl)),
              ),
              const SizedBox(height: _cardSpacing),
              _VersionCard(),
              const SizedBox(height: _cardSpacing),
              SettingCard(
                leading: Icon(Icons.restart_alt, color: theme.colorScheme.error),
                title: AppStrings.resetAppTitle,
                subtitle: AppStrings.resetAppSubtitle,
                isDestructive: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showResetConfirmation(context, ref),
              ),
              const SizedBox(height: 16),
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

}

/// Version card; in debug builds, tap 7 times to cycle dev subscription override.
class _VersionCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_VersionCard> createState() => _VersionCardState();
}

class _VersionCardState extends ConsumerState<_VersionCard> {
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
    return SettingCard(
      title: 'Version',
      subtitle: AppStrings.versionSubtitle,
      trailing: _version.isNotEmpty ? Text(_version) : null,
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

