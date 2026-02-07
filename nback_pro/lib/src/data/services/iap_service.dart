import 'dart:async';

import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/constants/iap_constants.dart';
import '../../data/models/subscription_state.dart';

/// Handles in-app purchases: load products, buy, restore, and derives subscription state
/// from purchase stream. Create products in App Store Connect and Play Console with
/// [IapConstants] IDs.
class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final Set<String> _ownedProductIds = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _stateController = StreamController<SubscriptionState>.broadcast();

  Stream<SubscriptionState> get stateStream => _stateController.stream;

  SubscriptionState get state => _stateFromOwned();

  bool _initialized = false;

  /// Call once at app start (e.g. from a provider or main).
  /// Swallows errors so the app runs when IAP is unavailable (e.g. emulator, no Play Store).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        _stateController.add(SubscriptionState.free);
        return;
      }
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (_) {},
      );
      _stateController.add(_stateFromOwned());
      await restorePurchases();
    } on PlatformException catch (_) {
      // Billing unavailable (e.g. emulator, channel-error, no Play Services).
      _stateController.add(SubscriptionState.free);
    } catch (_) {
      _stateController.add(SubscriptionState.free);
    }
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final id = purchase.productID;
        if (IapConstants.allProductIds.contains(id)) {
          _ownedProductIds.add(id);
          _iap.completePurchase(purchase);
        }
      }
    }
    _stateController.add(_stateFromOwned());
  }

  SubscriptionState _stateFromOwned() {
    if (_ownedProductIds.contains(IapConstants.proLifetime)) {
      return SubscriptionState.premiumActive;
    }
    if (_ownedProductIds.contains(IapConstants.proMonthly) ||
        _ownedProductIds.contains(IapConstants.proYearly)) {
      return SubscriptionState.premiumActive;
    }
    return SubscriptionState.free;
  }

  /// Load product details for the paywall. Returns empty if store unavailable.
  Future<List<ProductDetails>> loadProducts() async {
    final available = await _iap.isAvailable();
    if (!available) return [];
    final response = await _iap.queryProductDetails(IapConstants.allProductIds);
    if (response.notFoundIDs.isNotEmpty) {
      // Some products not configured in store yet
    }
    return response.productDetails;
  }

  /// Start purchase for [productId]. Result comes via [stateStream].
  Future<bool> buy(String productId) async {
    final products = await loadProducts();
    final product = products.where((p) => p.id == productId).firstOrNull;
    if (product == null) return false;
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  /// Restore previous purchases. Result comes via [stateStream].
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
    _stateController.close();
  }
}
