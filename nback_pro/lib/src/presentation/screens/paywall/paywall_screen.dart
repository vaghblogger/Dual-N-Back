import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';

/// Full-screen paywall with details. Replaces dialog for premium purchase.
const String _defaultTitle = '';
const String _defaultMessage = '';
const String _subscribeMonthlyLabel = 'Monthly — \$4.99';
const String _subscribeYearlyLabel = 'Yearly — \$29.99 (Best Value)';
const String _lifetimeLabel = 'Buy once — Lifetime access — \$49.99';
const String _restorePurchases = 'Restore purchases';

enum PaywallContext {
  train,
  theme,
  sessionLimit,
  progress,
}

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({
    super.key,
    this.title,
    this.message,
    required this.paywallContext,
    this.fromTutorial = false,
  });

  final String? title;
  final String? message;
  final PaywallContext paywallContext;
  final bool fromTutorial;

  void _dismiss(BuildContext context) {
    if (fromTutorial) {
      context.go('/home');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Pro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _dismiss(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              if ((title ?? _defaultTitle).isNotEmpty)
                Text(
                  title ?? _defaultTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              if ((title ?? _defaultTitle).isNotEmpty) const SizedBox(height: 12),
              if ((message ?? _defaultMessage).isNotEmpty)
                Text(
                  message ?? _defaultMessage,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              if ((message ?? _defaultMessage).isNotEmpty) const SizedBox(height: 20),
              Text(
                AppStrings.paywallBenefitsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 12),
              _PaywallBenefit(text: AppStrings.paywallBenefitNoAds),
              _PaywallBenefit(text: AppStrings.paywallBenefitLevels),
              _PaywallBenefit(text: AppStrings.paywallBenefitUnlimited),
              _PaywallBenefit(text: AppStrings.paywallBenefitInsights),
              _PaywallBenefit(text: AppStrings.paywallBenefitThemes),
              _PaywallBenefit(text: AppStrings.paywallBenefitControl),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _dismiss(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(_subscribeYearlyLabel),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _dismiss(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(_subscribeMonthlyLabel),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _dismiss(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(_lifetimeLabel),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {},
                child: const Text(_restorePurchases),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => _dismiss(context),
                child: const Text(AppStrings.willDoItLater),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaywallBenefit extends StatelessWidget {
  const _PaywallBenefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
