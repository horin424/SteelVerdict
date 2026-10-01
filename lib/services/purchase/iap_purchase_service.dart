import 'dart:async';
import 'dart:io' show Platform;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'purchase_service.dart';

/// Product IDs matching App Store / Play Store listings.
class ProductIds {
  static const String sub500Monthly = 'strategy_game_sub_500_monthly';
  static const String sub1000Monthly = 'strategy_game_sub_1000_monthly';
  static const String sub3000Monthly = 'strategy_game_sub_3000_monthly';
  static const String tickets10 = 'strategy_game_tickets_10';
  static const String tickets30 = 'strategy_game_tickets_30';
  static const String scenarioPack1 = 'strategy_game_scenario_pack_1';

  static const Set<String> all = {
    sub500Monthly,
    sub1000Monthly,
    sub3000Monthly,
    tickets10,
    tickets30,
    scenarioPack1,
  };

  static bool isSubscription(String productId) => productId.contains('_sub_');
}

class IapPurchaseService implements PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final StreamController<List<PurchaseDetails>> _purchaseController =
      StreamController.broadcast();

  /// Product IDs currently being verified server-side (dedupe stream events).
  final Set<String> _verifying = {};

  @override
  Future<void> initialize() async {
    try {
      _subscription = _iap.purchaseStream.listen(
        (purchases) {
          _purchaseController.add(purchases);
          _handlePurchases(purchases);
        },
        onError: (error) {
          debugPrint('IAP purchase stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('IapPurchaseService.initialize error: $e');
    }
  }

  void _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final key = '${purchase.productID}:${purchase.purchaseID ?? purchase.verificationData.serverVerificationData.hashCode}';
        if (_verifying.contains(key)) continue;
        _verifying.add(key);
        try {
          final ok = await _validateWithServer(purchase);
          if (!ok) {
            debugPrint('Server rejected purchase ${purchase.productID}');
            continue;
          }
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        } catch (e) {
          debugPrint('Purchase verify/complete error: $e');
        } finally {
          _verifying.remove(key);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchase.error}');
      }
    }
  }

  Future<bool> _validateWithServer(PurchaseDetails purchase) async {
    final platform = (!kIsWeb && Platform.isIOS) ? 'ios' : 'android';
    final isSubscription = ProductIds.isSubscription(purchase.productID);
    final callable = FirebaseFunctions.instance.httpsCallable(
      'validatePurchase',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final payload = <String, dynamic>{
      'platform': platform,
      'productId': purchase.productID,
      'isSubscription': isSubscription,
    };

    if (platform == 'android') {
      payload['purchaseToken'] =
          purchase.verificationData.serverVerificationData;
    } else {
      payload['receiptData'] =
          purchase.verificationData.serverVerificationData;
    }

    final result = await callable.call(payload);
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['granted'] != null;
  }

  @override
  Future<List<ProductDetails>> getProducts() async {
    try {
      final available = await _iap.isAvailable();
      if (!available) return [];

      final response = await _iap.queryProductDetails(ProductIds.all);
      if (response.error != null) {
        debugPrint('Product query error: ${response.error}');
        return [];
      }
      return response.productDetails;
    } catch (e) {
      debugPrint('getProducts error: $e');
      return [];
    }
  }

  @override
  Future<void> purchaseProduct(String productId) async {
    try {
      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isEmpty) {
        throw Exception('Product $productId not found');
      }
      final product = response.productDetails.first;
      final param = PurchaseParam(productDetails: product);

      if (ProductIds.isSubscription(productId)) {
        await _iap.buyNonConsumable(purchaseParam: param);
      } else {
        await _iap.buyConsumable(purchaseParam: param);
      }
    } catch (e) {
      debugPrint('purchaseProduct error: $e');
      rethrow;
    }
  }

  @override
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('restorePurchases error: $e');
      rethrow;
    }
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _purchaseController.stream;

  @override
  Future<bool> get isAvailable async {
    try {
      return await _iap.isAvailable();
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _purchaseController.close();
  }
}
