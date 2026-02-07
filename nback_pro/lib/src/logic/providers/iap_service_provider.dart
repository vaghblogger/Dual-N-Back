import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/subscription_state.dart';
import '../../data/services/iap_service.dart';

final iapServiceProvider = Provider<IapService>((ref) {
  final iap = IapService();
  iap.initialize();
  ref.onDispose(() => iap.dispose());
  return iap;
});

/// Subscription state from IAP purchase stream; rebuilds when purchases update.
final iapSubscriptionStateProvider = StreamProvider<SubscriptionState>((ref) {
  return ref.watch(iapServiceProvider).stateStream;
});
