/// Product IDs for in-app purchase. Must match App Store Connect and Play Console.
class IapConstants {
  IapConstants._();

  static const String proMonthly = 'pro_monthly';
  static const String proYearly = 'pro_yearly';
  static const String proLifetime = 'pro_lifetime';

  static const Set<String> subscriptionIds = {proMonthly, proYearly};
  static const Set<String> allProductIds = {proMonthly, proYearly, proLifetime};
}
