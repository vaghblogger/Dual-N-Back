import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/subscription_state.dart';
import 'iap_service_provider.dart';

/// Real subscription/lifetime state from IAP (purchases and restore).
/// When IAP is unavailable or not yet loaded, returns [SubscriptionState.free].
final subscriptionStateProvider = Provider<SubscriptionState>((ref) {
  final async = ref.watch(iapSubscriptionStateProvider);
  return async.valueOrNull ?? ref.read(iapServiceProvider).state;
});

/// Developer-only override. When non-null, feature gates use this instead of real state.
/// Toggled by tapping version 7 times in Settings; only active in debug builds.
final devSubscriptionOverrideProvider =
    StateProvider<SubscriptionState?>((ref) => null);

/// Effective state for all feature gates: dev override ?? real state.
final effectiveSubscriptionStateProvider = Provider<SubscriptionState>((ref) {
  if (kDebugMode) {
    final override = ref.watch(devSubscriptionOverrideProvider);
    if (override != null) return override;
  }
  return ref.watch(subscriptionStateProvider);
});

/// Convenience: true if user has premium access (subscription or lifetime).
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(effectiveSubscriptionStateProvider).isPremium;
});
