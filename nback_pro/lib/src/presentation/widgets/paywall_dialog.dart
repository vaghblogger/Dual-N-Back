import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/paywall/paywall_screen.dart';

export '../screens/paywall/paywall_screen.dart' show PaywallContext;

/// Opens full-screen paywall. When IAP is added: wire callbacks via route or provider.
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
  context.push('/paywall', extra: <String, dynamic>{
    'title': title,
    'message': message,
    'paywallContext': paywallContext,
    'fromTutorial': false,
  });
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
