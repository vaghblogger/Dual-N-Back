import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/stats_repository.dart';
import '../../../data/services/sync_service.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/onboarding_provider.dart';
import '../../../logic/providers/settings_provider.dart';
import '../../../logic/providers/stats_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 280, minHeight: 56),
                  child: OutlinedButton.icon(
                    onPressed: () => _signInWithGoogle(context, ref),
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text(AppStrings.signInWithGoogle),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
              if (Platform.isIOS) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 280, minHeight: 56),
                    child: OutlinedButton.icon(
                      onPressed: () => _signInWithApple(context, ref),
                      icon: const Icon(Icons.apple, size: 28),
                      label: const Text(AppStrings.signInWithApple),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _continueAsGuest(context, ref),
                child: const Text(AppStrings.continueAsGuest),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    try {
      final auth = ref.read(authServiceProvider);
      final user = await auth.signInWithGoogle();
      if (!context.mounted) return;
      if (user == null) {
        // User cancelled the picker, or Firebase is not initialized
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.signInCancelledOrUnavailable)),
        );
        return;
      }
      await setGuest(false);
      await setOnboardingComplete(true);
      if (!context.mounted) return;
      ref.invalidate(authStateChangesProvider);
      ref.invalidate(isGuestProvider);
      ref.invalidate(onboardingCompleteProvider);
      final storageId = user.uid.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      await SyncService().pull(
        user.uid,
        SettingsRepository(storageId),
        StatsRepository(storageId),
      );
      if (!context.mounted) return;
      _invalidateUserDataProviders(ref);
      context.go('/home');
    } catch (e) {
      if (context.mounted) {
        String message = AppStrings.authFailed;
        if (e is StateError) {
          message = e.message;
        } else if (e is PlatformException &&
            (e.message?.toLowerCase().contains('sign in') == true ||
                e.message?.toLowerCase().contains('sign_in') == true)) {
          message = AppStrings.signInFailedWebClientId;
        } else if (e is Exception) {
          message = e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  Future<void> _signInWithApple(BuildContext context, WidgetRef ref) async {
    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithApple();
      if (!context.mounted) return;
      await setGuest(false);
      await setOnboardingComplete(true);
      if (!context.mounted) return;
      ref.invalidate(authStateChangesProvider);
      ref.invalidate(isGuestProvider);
      ref.invalidate(onboardingCompleteProvider);
      _invalidateUserDataProviders(ref);
      context.go('/home');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.authFailed)),
        );
      }
    }
  }

  Future<void> _continueAsGuest(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.guestModeWarningTitle),
        content: const Text(AppStrings.guestModeWarningMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.yes),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await setGuest(true);
    await setOnboardingComplete(true);
    if (!context.mounted) return;
    ref.invalidate(isGuestProvider);
    ref.invalidate(onboardingCompleteProvider);
    _invalidateUserDataProviders(ref);
    context.go('/home', extra: {'from_continue_guest': true});
  }

  static void _invalidateUserDataProviders(WidgetRef ref) {
    ref.invalidate(settingsProvider);
    ref.invalidate(allSessionsProvider);
    ref.invalidate(averageNProvider);
    ref.invalidate(highestNProvider);
    ref.invalidate(currentStreakProvider);
    ref.invalidate(streakDataProvider);
    ref.invalidate(isChallengeCompleteTodayProvider);
    ref.invalidate(daysTrainedInLast7DaysProvider);
    ref.invalidate(last7DaysCompletedProvider);
  }
}
