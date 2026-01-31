import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/onboarding_provider.dart';

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
              const SizedBox(height: 48),
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _signInWithGoogle(context, ref),
                icon: const Icon(Icons.g_mobiledata),
                label: const Text(AppStrings.signInWithGoogle),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              if (Platform.isIOS) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _signInWithApple(context, ref),
                  icon: const Icon(Icons.apple),
                  label: const Text(AppStrings.signInWithApple),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _continueAsGuest(context, ref),
                child: const Text(AppStrings.continueAsGuest),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithGoogle();
      if (!context.mounted) return;
      await setOnboardingComplete(true);
      if (!context.mounted) return;
      ref.invalidate(onboardingCompleteProvider);
      context.go('/home');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.authFailed)),
        );
      }
    }
  }

  Future<void> _signInWithApple(BuildContext context, WidgetRef ref) async {
    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithApple();
      if (!context.mounted) return;
      await setOnboardingComplete(true);
      if (!context.mounted) return;
      ref.invalidate(onboardingCompleteProvider);
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
    await setOnboardingComplete(true);
    if (!context.mounted) return;
    ref.invalidate(onboardingCompleteProvider);
    context.go('/home');
  }
}
