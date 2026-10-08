import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// An Android plan change: the subscription being replaced, and whether the
/// new one ranks higher.
class PlanChange {
  const PlanChange(this.current, {required this.upgrade});

  final PurchaseDetails current;
  final bool upgrade;
}

/// What IapPurchaseService needs from the store. The plugin is wrapped here so
/// the purchase rules can be tested with a fake store.
abstract class StoreGateway {
  bool get isAndroid;

  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<bool> isAvailable();

  /// One ProductDetails per product. An Android subscription comes as its
  /// base plan only.
  Future<List<ProductDetails>> products(Set<String> ids);

  /// Android: the purchases Play still holds (owned, not consumed). Empty on iOS.
  Future<List<PurchaseDetails>> pastPurchases();

  /// Opens the store's sheet. False when it couldn't be opened.
  Future<bool> buy(
    ProductDetails product, {
    required String accountId,
    required bool consumable,
    PlanChange? planChange,
  });

  /// Android: uses up a ticket pack, so it can be bought again; true when done.
  /// iOS has nothing to consume (complete() finishes it) and returns false.
  Future<bool> consume(PurchaseDetails purchase);

  /// Finishes the transaction (iOS) or acknowledges the purchase (Android).
  Future<void> complete(PurchaseDetails purchase);

  Future<void> restore();
}

class PluginStoreGateway implements StoreGateway {
  final InAppPurchase _iap = InAppPurchase.instance;

  @override
  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  InAppPurchaseAndroidPlatformAddition get _android =>
      _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<List<ProductDetails>> products(Set<String> ids) async {
    if (!await _iap.isAvailable()) return const [];
    final response = await _iap.queryProductDetails(ids);
    if (response.error != null) {
      debugPrint('Product query error: ${response.error}');
    }
    return basePlansOnly(response.productDetails);
  }

  /// Play lists a subscription once per offer. Keep only the base plan, so a
  /// trial or discount offer added later in Play Console is never picked by
  /// accident (B30).
  @visibleForTesting
  static List<ProductDetails> basePlansOnly(List<ProductDetails> products) {
    return products.where((p) {
      if (p is! GooglePlayProductDetails || p.subscriptionIndex == null) return true;
      final offers = p.productDetails.subscriptionOfferDetails ?? const [];
      return offers[p.subscriptionIndex!].offerId == null;
    }).toList();
  }

  @override
  Future<List<PurchaseDetails>> pastPurchases() async {
    if (!isAndroid) return const [];
    final response = await _android.queryPastPurchases();
    if (response.error != null) {
      debugPrint('Past purchases query error: ${response.error}');
    }
    return response.pastPurchases;
  }

  @override
  Future<bool> buy(
    ProductDetails product, {
    required String accountId,
    required bool consumable,
    PlanChange? planChange,
  }) {
    final PurchaseParam param;
    if (isAndroid) {
      param = GooglePlayPurchaseParam(
        productDetails: product,
        applicationUserName: accountId,
        // Without this, buying a second plan starts a second subscription
        // instead of switching (A6). Upgrades start now and charge the
        // prorated difference; downgrades start at the next renewal (D1).
        changeSubscriptionParam: planChange == null
            ? null
            : ChangeSubscriptionParam(
                oldPurchaseDetails: planChange.current as GooglePlayPurchaseDetails,
                replacementMode: planChange.upgrade
                    ? ReplacementMode.chargeProratedPrice
                    : ReplacementMode.deferred,
              ),
      );
    } else {
      param = PurchaseParam(productDetails: product, applicationUserName: accountId);
    }
    if (!consumable) return _iap.buyNonConsumable(purchaseParam: param);
    // On Android a ticket pack is consumed only after the server has granted
    // it (B30); consumed at once, a failed server call would lose it. iOS
    // requires autoConsume and finishes the purchase in complete().
    return _iap.buyConsumable(purchaseParam: param, autoConsume: !isAndroid);
  }

  @override
  Future<bool> consume(PurchaseDetails purchase) async {
    if (!isAndroid) return false;
    final result = await _android.consumePurchase(purchase);
    if (result.responseCode != BillingResponse.ok) {
      throw StateError('Play could not consume the purchase: ${result.responseCode}');
    }
    return true;
  }

  @override
  Future<void> complete(PurchaseDetails purchase) => _iap.completePurchase(purchase);

  @override
  Future<void> restore() => _iap.restorePurchases();
}
