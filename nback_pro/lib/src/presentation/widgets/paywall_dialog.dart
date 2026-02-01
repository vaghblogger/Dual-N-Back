import 'package:flutter/material.dart';

/// Copy from PaymentGateway: soft gate messaging.
const String _defaultTitle = "You're progressing well.";
const String _defaultMessage =
    "Level 4 increases working-memory load significantly.\n\n"
    "Unlock advanced training to continue improving.";
const String _continueTomorrow = 'Continue tomorrow';
const String _continueWithDefault = 'Continue with default theme';
const String _chooseLowerN = 'Choose lower N';
const String _notNow = 'Not now';

/// Pricing placeholders (plan: India ₹199/₹1199, US $4.99/$29.99; Lifetime ₹2499/$49.99).
/// Replace with store product prices when IAP is integrated.
const String _subscribeMonthlyLabel = 'Monthly — \$4.99';
const String _subscribeYearlyLabel = 'Yearly — \$29.99 (Best Value)';
const String _lifetimeLabel = 'Buy once — Lifetime access — \$49.99';
const String _restorePurchases = 'Restore purchases';

/// Context for which feature triggered the paywall (affects dismiss button label).
enum PaywallContext {
  /// N-level or session limit — show "Choose lower N" or "Continue tomorrow".
  train,
  /// Theme selection — show "Continue with default theme".
  theme,
  /// Daily session limit — show "Continue tomorrow".
  sessionLimit,
  /// Progress / Brain Insights — show "Not now".
  progress,
}

/// Reusable paywall dialog per plan section 5 and 1a: Subscribe (monthly/yearly),
/// Buy once — Lifetime access, Restore purchases, and dismiss.
/// When IAP is added: wire [onSubscribeMonthly], [onSubscribeYearly], [onLifetime], [onRestore].
void showPaywallDialog(
  BuildContext context, {
  String? title,
  String? message,
  required PaywallContext paywallContext,
  VoidCallback? onUnlockPro,
  VoidCallback? onDismiss,
  VoidCallback? onSubscribeMonthly,
  VoidCallback? onSubscribeYearly,
  VoidCallback? onLifetime,
  VoidCallback? onRestore,
}) {
  final dismissLabel = switch (paywallContext) {
    PaywallContext.train => _chooseLowerN,
    PaywallContext.theme => _continueWithDefault,
    PaywallContext.sessionLimit => _continueTomorrow,
    PaywallContext.progress => _notNow,
  };

  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title ?? _defaultTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message ?? _defaultMessage),
            const SizedBox(height: 20),
            // Subscribe: Yearly (Best Value)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onSubscribeYearly != null) {
                  onSubscribeYearly();
                } else {
                  onUnlockPro?.call();
                }
              },
              child: const Text(_subscribeYearlyLabel),
            ),
            const SizedBox(height: 8),
            // Subscribe: Monthly
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onSubscribeMonthly != null) {
                  onSubscribeMonthly();
                } else {
                  onUnlockPro?.call();
                }
              },
              child: const Text(_subscribeMonthlyLabel),
            ),
            const SizedBox(height: 12),
            // Buy once — Lifetime access
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onLifetime != null) {
                  onLifetime();
                } else {
                  onUnlockPro?.call();
                }
              },
              child: const Text(_lifetimeLabel),
            ),
            const SizedBox(height: 16),
            // Restore purchases
            TextButton(
              onPressed: () {
                onRestore?.call();
              },
              child: const Text(_restorePurchases),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: Text(dismissLabel),
        ),
      ],
    ),
  );
}

/// Paywall for Progress / Brain Insights. Uses [PaywallContext.progress].
void showPaywallDialogProgress(
  BuildContext context, {
  VoidCallback? onUnlockPro,
  VoidCallback? onDismiss,
  VoidCallback? onSubscribeMonthly,
  VoidCallback? onSubscribeYearly,
  VoidCallback? onLifetime,
  VoidCallback? onRestore,
}) {
  showPaywallDialog(
    context,
    title: "You're progressing well.",
    message:
        'Unlock weekly & monthly trends, audio vs visual breakdown, '
        'performance heatmap, and export.',
    paywallContext: PaywallContext.progress,
    onUnlockPro: onUnlockPro,
    onDismiss: onDismiss,
    onSubscribeMonthly: onSubscribeMonthly,
    onSubscribeYearly: onSubscribeYearly,
    onLifetime: onLifetime,
    onRestore: onRestore,
  );
}

/// Paywall for daily session limit (2 sessions). Uses [PaywallContext.sessionLimit].
void showPaywallDialogSessionLimit(
  BuildContext context, {
  VoidCallback? onUnlockPro,
  VoidCallback? onDismiss,
  VoidCallback? onSubscribeMonthly,
  VoidCallback? onSubscribeYearly,
  VoidCallback? onLifetime,
  VoidCallback? onRestore,
}) {
  showPaywallDialog(
    context,
    title: "You're progressing well.",
    message:
        "You've completed 2 sessions today.\n\n"
        "Unlock Pro for unlimited sessions.",
    paywallContext: PaywallContext.sessionLimit,
    onUnlockPro: onUnlockPro,
    onDismiss: onDismiss,
    onSubscribeMonthly: onSubscribeMonthly,
    onSubscribeYearly: onSubscribeYearly,
    onLifetime: onLifetime,
    onRestore: onRestore,
  );
}
