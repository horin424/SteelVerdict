// The app side of purchases (A6, B13, B30), with a fake store and a fake
// validatePurchase: what is consumed, finished or left open after each answer.
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:strategy_game/services/purchase/iap_purchase_service.dart';
import 'package:strategy_game/services/purchase/purchase_account_id.dart';
import 'package:strategy_game/services/purchase/purchase_service.dart';
import 'package:strategy_game/services/purchase/store_gateway.dart';

PurchaseDetails purchase(String productId, String id,
        {PurchaseStatus status = PurchaseStatus.purchased, bool open = true}) =>
    PurchaseDetails(
      purchaseID: id,
      productID: productId,
      verificationData: PurchaseVerificationData(
          localVerificationData: '', serverVerificationData: 'token-$id', source: 'test'),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = open;

class FakeStore implements StoreGateway {
  FakeStore({this.isAndroid = true});

  @override
  final bool isAndroid;

  final StreamController<List<PurchaseDetails>> stream = StreamController.broadcast();
  final List<String> consumed = [];
  final List<String> completed = [];
  final List<({String productId, String accountId, bool consumable, PlanChange? planChange})> bought = [];

  /// What Play still holds (Android).
  List<PurchaseDetails> past = [];

  /// What a restore delivers.
  List<PurchaseDetails> restorable = [];

  /// What the store reports once its sheet has opened; nothing when null.
  PurchaseDetails? Function(String productId)? onBuy;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => stream.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<ProductDetails>> products(Set<String> ids) async => [
        for (final id in ids)
          ProductDetails(
              id: id, title: id, description: '', price: '¥0', rawPrice: 0, currencyCode: 'JPY'),
      ];

  @override
  Future<List<PurchaseDetails>> pastPurchases() async => isAndroid ? past : const [];

  @override
  Future<bool> buy(ProductDetails product,
      {required String accountId, required bool consumable, PlanChange? planChange}) async {
    bought.add((
      productId: product.id,
      accountId: accountId,
      consumable: consumable,
      planChange: planChange,
    ));
    final p = onBuy?.call(product.id);
    if (p != null) scheduleMicrotask(() => stream.add([p]));
    return true;
  }

  @override
  Future<bool> consume(PurchaseDetails p) async {
    if (!isAndroid) return false;
    consumed.add(p.purchaseID!);
    return true;
  }

  @override
  Future<void> complete(PurchaseDetails p) async => completed.add(p.purchaseID!);

  @override
  Future<void> restore() async => stream.add([
        for (final p in restorable) p..status = PurchaseStatus.restored,
      ]);
}

/// A fake validatePurchase: records each request and answers with [answer].
class FakeServer {
  final List<Map<String, dynamic>> requests = [];
  Map<String, dynamic> Function(Map<String, dynamic> request) answer =
      (_) => {'status': 'granted', 'granted': 'tickets', 'amount': 10};

  Future<Map<String, dynamic>> call(Map<String, dynamic> request) async {
    requests.add(request);
    return answer(request);
  }
}

Map<String, dynamic> Function(Map<String, dynamic>) serverDown =
    (_) => throw Exception('unavailable');

void main() {
  late FakeStore store;
  late FakeServer server;
  late IapPurchaseService service;
  late List<PurchaseOutcome> outcomes;

  IapPurchaseService start({bool android = true}) {
    store = FakeStore(isAndroid: android);
    service = IapPurchaseService(
      uid: 'test-uid-123',
      store: store,
      validate: server.call,
      restoreQuietPeriod: const Duration(milliseconds: 100),
    );
    outcomes = [];
    service.outcomes.listen(outcomes.add);
    return service;
  }

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  setUp(() => server = FakeServer());

  test('the account ID is the same UUID as the server computes', () {
    expect(purchaseAccountId('test-uid-123'), '6c038dfe-22ce-5098-b65d-42d915deaa7a');
  });

  group('buying', () {
    test('a ticket pack is consumed only after the server grants it (B30)', () async {
      start();
      await service.initialize();
      store.onBuy = (id) => purchase(id, 'p1');

      final outcome = await service.purchaseProduct(ProductIds.tickets10);

      expect(outcome.status, PurchaseOutcomeStatus.granted);
      expect(outcome.amount, 10);
      expect(outcome.userInitiated, isTrue);
      expect(store.consumed, ['p1']);
      expect(store.bought.single.consumable, isTrue);
      expect(store.bought.single.accountId, purchaseAccountId('test-uid-123'));
      expect(server.requests.single,
          {'platform': 'android', 'productId': ProductIds.tickets10, 'purchaseToken': 'token-p1'});
    });

    test('server down: the pack stays open and is granted at the next start', () async {
      server.answer = serverDown;
      start();
      await service.initialize();
      store.onBuy = (id) => purchase(id, 'p1');

      final outcome = await service.purchaseProduct(ProductIds.tickets10);
      expect(outcome.status, PurchaseOutcomeStatus.retryLater);
      expect(store.consumed, isEmpty);
      expect(store.completed, isEmpty);

      // Next start: Play still holds the pack, so it is sent again.
      server.answer = (_) => {'status': 'granted', 'granted': 'tickets', 'amount': 10};
      final heldByPlay = purchase(ProductIds.tickets10, 'p1');
      start();
      store.past = [heldByPlay];
      await service.initialize();
      await settle();

      expect(store.consumed, ['p1']);
      expect(outcomes.single.status, PurchaseOutcomeStatus.granted);
      expect(outcomes.single.userInitiated, isFalse, reason: 'announced app-wide');
    });

    test('at start-up, acknowledged subscriptions are not sent again', () async {
      start();
      store.past = [
        purchase(ProductIds.sub1000Monthly, 's1', open: false), // acknowledged
        purchase(ProductIds.scenarioPack1, 'k1'), // not acknowledged yet
        purchase(ProductIds.tickets30, 't1', status: PurchaseStatus.pending),
      ];
      await service.initialize();
      expect(server.requests.map((r) => r['productId']), [ProductIds.scenarioPack1]);
      expect(store.completed, ['k1']);
    });

    test('iOS: a pack is finished, not consumed, and the signed transaction is sent', () async {
      start(android: false);
      await service.initialize();
      store.onBuy = (id) => purchase(id, 'i1');

      final outcome = await service.purchaseProduct(ProductIds.tickets30);

      expect(outcome.isGranted, isTrue);
      expect(store.consumed, isEmpty);
      expect(store.completed, ['i1']);
      expect(server.requests.single['receiptData'], 'token-i1');
      expect(server.requests.single['platform'], 'ios');
    });

    test('a subscription and the scenario pack are bought as non-consumables (B13)', () async {
      server.answer = (r) => {'status': 'granted', 'granted': 'subscription', 'tier': 'sub500'};
      start();
      await service.initialize();
      store.onBuy = (id) => purchase(id, 'n-$id');

      await service.purchaseProduct(ProductIds.sub500Monthly);
      await service.purchaseProduct(ProductIds.scenarioPack1);

      expect(store.bought.map((b) => b.consumable), [false, false]);
      expect(store.consumed, isEmpty);
      expect(store.completed, ['n-${ProductIds.sub500Monthly}', 'n-${ProductIds.scenarioPack1}']);
    });

    test('closing the store sheet: canceled, nothing sent to the server', () async {
      start();
      await service.initialize();
      store.onBuy = (id) => purchase(id, 'c1', status: PurchaseStatus.canceled, open: false);

      final outcome = await service.purchaseProduct(ProductIds.tickets10);

      expect(outcome.status, PurchaseOutcomeStatus.canceled);
      expect(server.requests, isEmpty);
    });

    test('a pending payment: pending, nothing finished; granted later in the background', () async {
      start();
      await service.initialize();
      store.onBuy = (id) => purchase(id, 'q1', status: PurchaseStatus.pending, open: false);

      final outcome = await service.purchaseProduct(ProductIds.tickets30);
      expect(outcome.status, PurchaseOutcomeStatus.pending);
      expect(server.requests, isEmpty);

      // The convenience-store payment completes later.
      store.stream.add([purchase(ProductIds.tickets30, 'q1')]);
      await settle();
      expect(store.consumed, ['q1']);
      expect(outcomes.last.status, PurchaseOutcomeStatus.granted);
      expect(outcomes.last.userInitiated, isFalse);
    });

    test('the same purchase delivered twice is checked once', () async {
      start();
      await service.initialize();
      final p = purchase(ProductIds.tickets10, 'd1');
      store.stream.add([p]);
      store.stream.add([p]);
      await settle();
      expect(server.requests, hasLength(1));
    });
  });

  group('refusals', () {
    test("another account's pack is finished but not consumed, so it still reaches that account",
        () async {
      server.answer = (_) => {'status': 'refused', 'reason': 'other_account'};
      start();
      await service.initialize();
      store.onBuy = (id) => purchase(id, 'r1');

      final outcome = await service.purchaseProduct(ProductIds.tickets10);

      expect(outcome.status, PurchaseOutcomeStatus.refused);
      expect(outcome.reason, 'other_account');
      expect(store.consumed, isEmpty);
      expect(store.completed, ['r1']);
    });

    test('an invalid pack is consumed, so Play stops delivering it', () async {
      server.answer = (_) => {'status': 'refused', 'reason': 'store_unknown_purchase'};
      start();
      await service.initialize();
      store.onBuy = (id) => purchase(id, 'r2');

      await service.purchaseProduct(ProductIds.tickets10);

      expect(store.consumed, ['r2']);
    });

    test('the server says pending: nothing finished', () async {
      server.answer = (_) => {'status': 'pending'};
      start();
      await service.initialize();
      store.onBuy = (id) => purchase(id, 'w1');

      final outcome = await service.purchaseProduct(ProductIds.sub1000Monthly);

      expect(outcome.status, PurchaseOutcomeStatus.pending);
      expect(store.completed, isEmpty);
      expect(store.consumed, isEmpty);
    });
  });

  group('Android plan changes (A6)', () {
    test('Commander to General: an upgrade of the current subscription', () async {
      start();
      final current = purchase(ProductIds.sub500Monthly, 'old', open: false);
      store.past = [current];
      await service.initialize();
      store.onBuy = (id) => purchase(id, 'new');

      await service.purchaseProduct(ProductIds.sub1000Monthly);

      expect(store.bought.single.planChange?.current, same(current));
      expect(store.bought.single.planChange?.upgrade, isTrue);
    });

    test('Warlord to Commander: a downgrade', () async {
      start();
      store.past = [purchase(ProductIds.sub3000Monthly, 'old', open: false)];
      await service.initialize();
      store.onBuy = (id) => purchase(id, 'new');

      await service.purchaseProduct(ProductIds.sub500Monthly);

      expect(store.bought.single.planChange?.upgrade, isFalse);
    });

    test('no plan yet: a plain purchase; and iOS never passes a plan change', () async {
      start();
      await service.initialize();
      store.onBuy = (id) => purchase(id, 'new');
      await service.purchaseProduct(ProductIds.sub1000Monthly);
      expect(store.bought.single.planChange, isNull);

      start(android: false);
      store.past = [purchase(ProductIds.sub500Monthly, 'old', open: false)];
      await service.initialize();
      store.onBuy = (id) => purchase(id, 'new2');
      await service.purchaseProduct(ProductIds.sub1000Monthly);
      expect(store.bought.single.planChange, isNull);
    });
  });

  group('restore', () {
    test('ends with what each restored purchase gave', () async {
      server.answer = (r) => {'status': 'already_granted', 'granted': 'subscription'};
      start();
      await service.initialize();
      store.restorable = [
        purchase(ProductIds.sub1000Monthly, 's1', open: false),
        purchase(ProductIds.scenarioPack1, 'k1', open: false),
      ];

      final restored = await service.restorePurchases();

      expect(restored.map((o) => o.status),
          [PurchaseOutcomeStatus.alreadyGranted, PurchaseOutcomeStatus.alreadyGranted]);
      expect(restored.every((o) => o.userInitiated), isTrue);
    });

    test('nothing to restore: an empty list', () async {
      start();
      await service.initialize();
      expect(await service.restorePurchases(), isEmpty);
    });
  });

  test('Play subscriptions: only the base plan, never an offer listed before it', () {
    PricingPhaseWrapper phase(String price) => PricingPhaseWrapper(
          billingCycleCount: 0,
          billingPeriod: 'P1M',
          formattedPrice: price,
          priceAmountMicros: 1000000000,
          priceCurrencyCode: 'JPY',
          recurrenceMode: RecurrenceMode.infiniteRecurring,
        );
    final listed = GooglePlayProductDetails.fromProductDetails(ProductDetailsWrapper(
      description: '',
      name: 'General',
      productId: ProductIds.sub1000Monthly,
      productType: ProductType.subs,
      title: 'General',
      subscriptionOfferDetails: [
        SubscriptionOfferDetailsWrapper(
            basePlanId: 'monthly',
            offerId: 'free-trial',
            offerTags: const [],
            offerIdToken: 'trial-token',
            pricingPhases: [phase('¥0')]),
        SubscriptionOfferDetailsWrapper(
            basePlanId: 'monthly',
            offerTags: const [],
            offerIdToken: 'base-token',
            pricingPhases: [phase('¥1,000')]),
      ],
    ));
    final kept = PluginStoreGateway.basePlansOnly(listed);
    expect(kept, hasLength(1));
    expect((kept.single as GooglePlayProductDetails).offerToken, 'base-token');
  });
}
