import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../services/purchase/purchase_service.dart';
import '../../services/purchase/iap_purchase_service.dart';
import '../home/home_providers.dart';

// Purchase service provider
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = IapPurchaseService();
  service.initialize();
  ref.onDispose(service.dispose);
  return service;
});

// Products provider
final productsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  final purchaseService = ref.watch(purchaseServiceProvider);
  return await purchaseService.getProducts();
});

// Purchase controller state
class PurchaseControllerState {
  final bool isPurchasing;
  final String? error;
  final String? successMessage;

  const PurchaseControllerState({
    this.isPurchasing = false,
    this.error,
    this.successMessage,
  });

  PurchaseControllerState copyWith({
    bool? isPurchasing,
    String? error,
    String? successMessage,
  }) {
    return PurchaseControllerState(
      isPurchasing: isPurchasing ?? this.isPurchasing,
      error: error,
      successMessage: successMessage,
    );
  }
}

class PurchaseController extends StateNotifier<PurchaseControllerState> {
  final Ref _ref;

  PurchaseController(this._ref) : super(const PurchaseControllerState());

  Future<void> purchase(String productId) async {
    state = state.copyWith(isPurchasing: true, error: null, successMessage: null);
    try {
      final purchaseService = _ref.read(purchaseServiceProvider);
      await purchaseService.purchaseProduct(productId);
      state = state.copyWith(isPurchasing: false, successMessage: 'purchase_initiated');

      // Log analytics
      final analytics = _ref.read(analyticsServiceProvider);
      await analytics.logSubscriptionPurchased(productId);
    } catch (e) {
      state = state.copyWith(isPurchasing: false, error: 'purchase_failed:$e');
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isPurchasing: true, error: null);
    try {
      final purchaseService = _ref.read(purchaseServiceProvider);
      await purchaseService.restorePurchases();
      state = state.copyWith(isPurchasing: false, successMessage: 'purchases_restored');
    } catch (e) {
      state = state.copyWith(isPurchasing: false, error: 'restore_failed:$e');
    }
  }
}

final purchaseControllerProvider =
    StateNotifierProvider<PurchaseController, PurchaseControllerState>((ref) {
  return PurchaseController(ref);
});

// Subscription plan data
class SubscriptionPlan {
  final String productId;
  final String title;
  final String price;
  final int dailyTickets;
  final List<String> features;
  final bool isPopular;

  const SubscriptionPlan({
    required this.productId,
    required this.title,
    required this.price,
    required this.dailyTickets,
    required this.features,
    this.isPopular = false,
  });
}

const List<SubscriptionPlan> kSubscriptionPlans = [
  SubscriptionPlan(
    productId: 'strategy_game_sub_500_monthly',
    title: 'Commander',
    price: '¥500/mo',
    dailyTickets: 10,
    features: [
      '10 daily tickets',
      'All basic scenarios',
      'Save up to 20 strategies',
      'Priority battle queue',
    ],
  ),
  SubscriptionPlan(
    productId: 'strategy_game_sub_1000_monthly',
    title: 'General',
    price: '¥1,000/mo',
    dailyTickets: 20,
    features: [
      '20 daily tickets',
      'Epic mode unlocked',
      'Unlimited war history',
      'Save up to 50 strategies',
      'All Commander features',
    ],
    isPopular: true,
  ),
  SubscriptionPlan(
    productId: 'strategy_game_sub_3000_monthly',
    title: 'Warlord',
    price: '¥3,000/mo',
    dailyTickets: 50,
    features: [
      '50 daily tickets',
      'All modes unlocked',
      'Boss battles enabled',
      'Unlimited everything',
      'All General features',
    ],
  ),
];
