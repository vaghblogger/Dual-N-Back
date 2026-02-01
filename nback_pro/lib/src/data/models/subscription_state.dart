/// Entitlement state for premium features.
/// User is premium if they have either an active subscription or a lifetime purchase.
enum SubscriptionState {
  /// No subscription, no lifetime purchase.
  free,

  /// Valid subscription or lifetime owned — full access.
  premiumActive,

  /// Subscription ended, no lifetime — downgraded access.
  premiumExpired,
}

extension SubscriptionStateX on SubscriptionState {
  bool get isPremium => this == SubscriptionState.premiumActive;
}
