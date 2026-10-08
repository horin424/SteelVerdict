import 'package:in_app_purchase/in_app_purchase.dart';

/// What happened to a purchase, once the store and the server have answered.
enum PurchaseOutcomeStatus {
  /// The server granted it now.
  granted,

  /// The server had granted it before (a renewal, a restore, a resend).
  alreadyGranted,

  /// The server refused it: another account's, refunded, expired, or not genuine.
  refused,

  /// The payment isn't complete yet (Ask to Buy, convenience-store payment).
  pending,

  /// The server couldn't be asked. The purchase stays open and is sent again
  /// at the next start.
  retryLater,

  /// The user closed the store's sheet.
  canceled,

  /// The store reported an error.
  failed,
}

class PurchaseOutcome {
  const PurchaseOutcome(
    this.productId,
    this.status, {
    this.reason,
    this.amount,
    this.tier,
    this.restored = false,
    this.userInitiated = false,
  });

  final String productId;
  final PurchaseOutcomeStatus status;

  /// The server's reason when refused, e.g. other_account, expired, refunded.
  final String? reason;

  /// Tickets added by a ticket pack.
  final int? amount;

  /// The user's tier after a subscription purchase.
  final String? tier;

  /// Came from a restore, or was sent again at start-up.
  final bool restored;

  /// Part of something the user is doing right now (buying, restoring), so
  /// the screen that started it tells the user. Other outcomes, such as a
  /// payment that completed later, are announced app-wide.
  final bool userInitiated;

  bool get isGranted =>
      status == PurchaseOutcomeStatus.granted ||
      status == PurchaseOutcomeStatus.alreadyGranted;

  PurchaseOutcome asUserInitiated() => PurchaseOutcome(
        productId,
        status,
        reason: reason,
        amount: amount,
        tier: tier,
        restored: restored,
        userInitiated: true,
      );

  @override
  String toString() =>
      'PurchaseOutcome($productId, ${status.name}${reason == null ? '' : ', $reason'})';
}

abstract class PurchaseService {
  /// Starts listening to the store. Call once, as soon as a user is signed in.
  Future<void> initialize();

  /// Get available products from the store.
  Future<List<ProductDetails>> getProducts();

  /// Opens the store's sheet for [productId] and completes with what happened:
  /// granted, pending, refused, canceled, ...
  Future<PurchaseOutcome> purchaseProduct(String productId);

  /// Restores past purchases and completes with what each of them gave. Empty
  /// when there was nothing to restore.
  Future<List<PurchaseOutcome>> restorePurchases();

  /// Every purchase the server has checked, including ones the user didn't
  /// start just now.
  Stream<PurchaseOutcome> get outcomes;

  /// Whether the store is available.
  Future<bool> get isAvailable;

  /// Dispose resources.
  void dispose();
}
