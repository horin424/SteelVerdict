import 'package:in_app_purchase/in_app_purchase.dart';

abstract class PurchaseService {
  /// Get available products from the store.
  Future<List<ProductDetails>> getProducts();

  /// Initiate a purchase for a given product ID.
  Future<void> purchaseProduct(String productId);

  /// Restore previous purchases.
  Future<void> restorePurchases();

  /// Stream of purchase updates.
  Stream<List<PurchaseDetails>> get purchaseStream;

  /// Whether the store is available.
  Future<bool> get isAvailable;

  /// Initialize purchase service (call once).
  Future<void> initialize();

  /// Dispose resources.
  void dispose();
}
