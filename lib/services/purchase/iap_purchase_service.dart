import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'purchase_account_id.dart';
import 'purchase_service.dart';
import 'store_gateway.dart';

enum ProductKind { subscription, consumable, nonConsumable }

/// Product IDs matching App Store / Play Store listings, and what each one is.
/// Must match functions/src/purchase/products.ts.
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

  static const Map<String, ProductKind> _kinds = {
    sub500Monthly: ProductKind.subscription,
    sub1000Monthly: ProductKind.subscription,
    sub3000Monthly: ProductKind.subscription,
    tickets10: ProductKind.consumable,
    tickets30: ProductKind.consumable,
    // Bought once, owned for good (B13).
    scenarioPack1: ProductKind.nonConsumable,
  };

  /// Subscriptions from the lowest plan to the highest.
  static const List<String> subscriptionsByRank = [
    sub500Monthly,
    sub1000Monthly,
    sub3000Monthly,
  ];

  /// Tickets in each ticket pack.
  static const Map<String, int> tickets = {tickets10: 10, tickets30: 30};

  static ProductKind? kindOf(String productId) => _kinds[productId];

  static bool isSubscription(String productId) =>
      kindOf(productId) == ProductKind.subscription;
}

/// Asks the server about a purchase (the validatePurchase function).
typedef PurchaseValidator = Future<Map<String, dynamic>> Function(
    Map<String, dynamic> request);

Future<Map<String, dynamic>> _callValidatePurchase(
    Map<String, dynamic> request) async {
  final callable = FirebaseFunctions.instance.httpsCallable(
    'validatePurchase',
    options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
  );
  final result = await callable.call(request);
  return Map<String, dynamic>.from(result.data as Map);
}

/// Buys, restores and checks purchases for one signed-in user.
///
/// Every purchase goes to the server first; only what the server has recorded
/// is finished in the store (B30):
/// - granted / already granted: a ticket pack is consumed (Android), anything
///   else finished or acknowledged;
/// - refused: finished too, so the store doesn't deliver it again forever;
/// - pending, or the server couldn't be asked: left open. Android sends it
///   again at the next start (initialize); StoreKit re-delivers it by itself.
class IapPurchaseService implements PurchaseService {
  IapPurchaseService({
    required String uid,
    StoreGateway? store,
    PurchaseValidator? validate,
    this.restoreQuietPeriod = const Duration(seconds: 2),
    this.purchaseTimeout = const Duration(minutes: 10),
  })  : accountId = purchaseAccountId(uid),
        _store = store ?? PluginStoreGateway(),
        _validate = validate ?? _callValidatePurchase;

  /// Attached to every purchase, so the server can tell whose it is.
  final String accountId;
  final StoreGateway _store;
  final PurchaseValidator _validate;

  /// A restore is over once no restored purchase has arrived or finished
  /// being checked for this long: nothing says when the last one has come.
  final Duration restoreQuietPeriod;

  /// How long purchaseProduct waits for the store's answer. A purchase that
  /// completes later is still checked, and announced app-wide.
  final Duration purchaseTimeout;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final StreamController<PurchaseOutcome> _outcomes =
      StreamController.broadcast();

  /// Purchases being checked, so one delivered twice is checked once.
  final Set<String> _checking = {};

  /// The user's own purchases in progress, by product.
  final Map<String, Completer<PurchaseOutcome>> _buying = {};

  _RestoreRun? _restore;

  @override
  Stream<PurchaseOutcome> get outcomes => _outcomes.stream;

  @override
  Future<void> initialize() async {
    _subscription ??= _store.purchaseStream.listen(
      (purchases) => _handle(purchases),
      onError: (Object error) => debugPrint('IAP purchase stream error: $error'),
    );
    // Android: Play holds a ticket pack until it is consumed and any purchase
    // until it is acknowledged, but tells the app only at a purchase or when
    // asked. Ask now, so a purchase the server never confirmed (no network,
    // app closed) is granted at the next start. iOS: StoreKit re-delivers
    // unfinished transactions to the listener by itself.
    if (!_store.isAndroid) return;
    try {
      final past = await _store.pastPurchases();
      await _handle(past.where(_needsResend).toList(), resent: true);
    } catch (e) {
      debugPrint('Resending open purchases failed: $e');
    }
  }

  static bool _needsResend(PurchaseDetails p) =>
      p.status == PurchaseStatus.purchased &&
      (ProductIds.kindOf(p.productID) == ProductKind.consumable ||
          p.pendingCompletePurchase);

  Future<void> _handle(List<PurchaseDetails> purchases,
      {bool resent = false}) async {
    for (final p in purchases) {
      final restored = resent || p.status == PurchaseStatus.restored;
      if (restored) _restore?.touch();
      switch (p.status) {
        case PurchaseStatus.pending:
          _emit(PurchaseOutcome(p.productID, PurchaseOutcomeStatus.pending,
              restored: restored));
        case PurchaseStatus.canceled:
          await _finish(p);
          _emit(PurchaseOutcome(p.productID, PurchaseOutcomeStatus.canceled,
              restored: restored));
        case PurchaseStatus.error:
          debugPrint('Purchase error: ${p.error}');
          await _finish(p);
          _emit(PurchaseOutcome(p.productID, PurchaseOutcomeStatus.failed,
              restored: restored));
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _check(p, restored: restored);
      }
    }
  }

  Future<void> _check(PurchaseDetails p, {required bool restored}) async {
    final key =
        '${p.productID}:${p.purchaseID ?? p.verificationData.serverVerificationData.hashCode}';
    if (!_checking.add(key)) return;
    final run = restored ? _restore : null;
    run?.checking++;
    try {
      _emit(await _askServer(p, restored: restored));
    } finally {
      _checking.remove(key);
      if (run != null) {
        run.checking--;
        run.touch();
      }
    }
  }

  Future<PurchaseOutcome> _askServer(PurchaseDetails p,
      {required bool restored}) async {
    final productId = p.productID;
    final Map<String, dynamic> answer;
    try {
      answer = await _validate({
        'platform': _store.isAndroid ? 'android' : 'ios',
        'productId': productId,
        // Android: the Play purchase token. iOS: StoreKit 2's signed transaction.
        if (_store.isAndroid)
          'purchaseToken': p.verificationData.serverVerificationData
        else
          'receiptData': p.verificationData.serverVerificationData,
      });
    } catch (e) {
      debugPrint('validatePurchase failed for $productId: $e');
      return PurchaseOutcome(productId, PurchaseOutcomeStatus.retryLater,
          restored: restored);
    }

    final isPack = ProductIds.kindOf(productId) == ProductKind.consumable;
    switch (answer['status']) {
      case 'granted':
      case 'already_granted':
        // The server has recorded it, so the store may forget it.
        await _release(p, consume: isPack);
        return PurchaseOutcome(
          productId,
          answer['status'] == 'granted'
              ? PurchaseOutcomeStatus.granted
              : PurchaseOutcomeStatus.alreadyGranted,
          amount: (answer['amount'] as num?)?.toInt(),
          tier: answer['tier'] as String?,
          restored: restored,
        );
      case 'refused':
        final reason = answer['reason'] as String?;
        // Finished, so it isn't delivered again forever. On Android a ticket
        // pack must be consumed for that, unless it is another account's:
        // kept, it still reaches that account at its next start.
        await _release(p, consume: isPack && !_isAnotherAccounts(reason));
        return PurchaseOutcome(productId, PurchaseOutcomeStatus.refused,
            reason: reason, restored: restored);
      case 'pending':
        return PurchaseOutcome(productId, PurchaseOutcomeStatus.pending,
            restored: restored);
      default:
        debugPrint('validatePurchase answered $answer for $productId');
        return PurchaseOutcome(productId, PurchaseOutcomeStatus.retryLater,
            restored: restored);
    }
  }

  static bool _isAnotherAccounts(String? reason) =>
      reason == 'other_account' || reason == 'claimed_by_other_account';

  /// Tells the store the purchase is dealt with: consumes an Android ticket
  /// pack (which also acknowledges it), finishes or acknowledges anything else.
  /// If the store can't be told, the purchase comes back later and the server,
  /// which has recorded it, answers the same again.
  Future<void> _release(PurchaseDetails p, {required bool consume}) async {
    try {
      if (consume && await _store.consume(p)) return;
    } catch (e) {
      debugPrint('Consuming ${p.productID} failed: $e');
      return;
    }
    await _finish(p);
  }

  Future<void> _finish(PurchaseDetails p) async {
    if (!p.pendingCompletePurchase) return;
    try {
      await _store.complete(p);
    } catch (e) {
      debugPrint('Completing ${p.productID} failed: $e');
    }
  }

  void _emit(PurchaseOutcome outcome) {
    var o = outcome;
    final run = _restore;
    if (o.restored) {
      if (run != null) {
        o = o.asUserInitiated();
        run.outcomes.add(o);
        run.touch();
      }
    } else {
      final buying = _buying.remove(o.productId);
      if (buying != null) {
        o = o.asUserInitiated();
        buying.complete(o);
      }
    }
    if (!_outcomes.isClosed) _outcomes.add(o);
  }

  @override
  Future<List<ProductDetails>> getProducts() async {
    try {
      return await _store.products(ProductIds.all);
    } catch (e) {
      debugPrint('getProducts error: $e');
      return const [];
    }
  }

  @override
  Future<PurchaseOutcome> purchaseProduct(String productId) async {
    final kind = ProductIds.kindOf(productId);
    if (kind == null) throw ArgumentError.value(productId, 'productId', 'unknown product');
    final products = await _store.products({productId});
    if (products.isEmpty) throw StateError('Product $productId not found');
    // Android: switch plans instead of starting a second subscription (A6).
    final planChange = kind == ProductKind.subscription && _store.isAndroid
        ? await _planChangeTo(productId)
        : null;

    _buying.remove(productId)?.complete(
        PurchaseOutcome(productId, PurchaseOutcomeStatus.canceled, userInitiated: true));
    final buying = Completer<PurchaseOutcome>();
    _buying[productId] = buying;
    final bool opened;
    try {
      opened = await _store.buy(
        products.first,
        accountId: accountId,
        consumable: kind == ProductKind.consumable,
        planChange: planChange,
      );
    } catch (_) {
      if (identical(_buying[productId], buying)) _buying.remove(productId);
      rethrow;
    }
    if (!opened && !buying.isCompleted) {
      _buying.remove(productId);
      return PurchaseOutcome(productId, PurchaseOutcomeStatus.failed, userInitiated: true);
    }
    return buying.future.timeout(purchaseTimeout, onTimeout: () {
      if (identical(_buying[productId], buying)) _buying.remove(productId);
      return PurchaseOutcome(productId, PurchaseOutcomeStatus.canceled, userInitiated: true);
    });
  }

  /// Android: the subscription the Play account holds now, if it is another
  /// plan than [productId].
  Future<PlanChange?> _planChangeTo(String productId) async {
    final ranks = ProductIds.subscriptionsByRank;
    for (final p in await _store.pastPurchases()) {
      if (p.status == PurchaseStatus.purchased &&
          ProductIds.isSubscription(p.productID) &&
          p.productID != productId) {
        return PlanChange(p,
            upgrade: ranks.indexOf(productId) > ranks.indexOf(p.productID));
      }
    }
    return null;
  }

  @override
  Future<List<PurchaseOutcome>> restorePurchases() async {
    final run = _restore = _RestoreRun();
    try {
      await _store.restore();
      run.touch();
      while (run.checking > 0 || run.quietFor < restoreQuietPeriod) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return List.unmodifiable(run.outcomes);
    } finally {
      if (identical(_restore, run)) _restore = null;
    }
  }

  @override
  Future<bool> get isAvailable async {
    try {
      return await _store.isAvailable();
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _buying.forEach((productId, buying) => buying.complete(PurchaseOutcome(
        productId, PurchaseOutcomeStatus.canceled, userInitiated: true)));
    _buying.clear();
    _outcomes.close();
  }
}

class _RestoreRun {
  final List<PurchaseOutcome> outcomes = [];
  int checking = 0;
  DateTime _lastActivity = DateTime.now();

  void touch() => _lastActivity = DateTime.now();

  Duration get quietFor => DateTime.now().difference(_lastActivity);
}
