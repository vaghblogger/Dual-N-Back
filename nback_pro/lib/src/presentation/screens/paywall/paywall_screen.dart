import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/iap_constants.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../logic/providers/iap_service_provider.dart';

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

class PaywallScreen extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _purchaseInProgress = false;
  bool _restoreInProgress = false;

  void _dismiss(BuildContext context) {
    if (widget.fromTutorial) {
      context.go('/home');
    } else {
      context.pop();
    }
  }

  Future<void> _buy(String productId) async {
    if (_purchaseInProgress) return;
    setState(() => _purchaseInProgress = true);
    try {
      final iap = ref.read(iapServiceProvider);
      final ok = await iap.buy(productId);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase could not be started. Check store availability.')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchaseInProgress = false);
    }
  }

  Future<void> _restore() async {
    if (_restoreInProgress) return;
    setState(() => _restoreInProgress = true);
    try {
      final iap = ref.read(iapServiceProvider);
      await iap.restorePurchases();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore finished. If you had a purchase, access is restored.')),
      );
    } finally {
      if (mounted) setState(() => _restoreInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _purchaseInProgress || _restoreInProgress;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Pro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: busy ? null : () => _dismiss(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveLayout.contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              if ((widget.title ?? _defaultTitle).isNotEmpty)
                Text(
                  widget.title ?? _defaultTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              if ((widget.title ?? _defaultTitle).isNotEmpty) const SizedBox(height: 12),
              if ((widget.message ?? _defaultMessage).isNotEmpty)
                Text(
                  widget.message ?? _defaultMessage,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              if ((widget.message ?? _defaultMessage).isNotEmpty) const SizedBox(height: 20),
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
                onPressed: busy ? null : () => _buy(IapConstants.proYearly),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(_subscribeYearlyLabel),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: busy ? null : () => _buy(IapConstants.proMonthly),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(_subscribeMonthlyLabel),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: busy ? null : () => _buy(IapConstants.proLifetime),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(_lifetimeLabel),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: busy ? null : _restore,
                child: const Text(_restorePurchases),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: busy ? null : () => _dismiss(context),
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
