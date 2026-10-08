import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../app.dart';
import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/error_snackbar.dart';
import '../../services/purchase/purchase_service.dart';
import '../../services/purchase/iap_purchase_service.dart';
import '../auth/auth_providers.dart';
import '../home/home_providers.dart';
import 'purchase_messages.dart';

/// The signed-in user's purchase service. It is made at sign-in, not when the
/// shop opens, so purchases left open are sent again at every start (B30).
/// Null while nobody is signed in. Another account gets its own service,
/// because every purchase carries the account's ID.
final purchaseServiceProvider = Provider<PurchaseService?>((ref) {
  final uid = ref.watch(
      authStateChangesProvider.select((auth) => auth.valueOrNull?.uid));
  if (uid == null) return null;
  final service = IapPurchaseService(uid: uid);
  service.initialize();
  ref.onDispose(service.dispose);
  return service;
});

/// Watched by App, so the purchase service runs from sign-in on. Acts on every
/// purchase the server has checked: refreshes the user's tickets and plan,
/// logs a new subscription, and announces a purchase that completed in the
/// background, such as a convenience-store payment made later.
final purchaseBootstrapProvider = Provider<void>((ref) {
  final service = ref.watch(purchaseServiceProvider);
  if (service == null) return;
  final subscription = service.outcomes.listen((outcome) {
    if (outcome.isGranted) ref.invalidate(currentUserModelProvider);
    if (outcome.status == PurchaseOutcomeStatus.granted &&
        ProductIds.isSubscription(outcome.productId)) {
      unawaited(ref
          .read(analyticsServiceProvider)
          .logSubscriptionPurchased(outcome.productId));
    }
    if (!outcome.userInitiated &&
        outcome.status == PurchaseOutcomeStatus.granted) {
      _announce(outcome);
    }
  });
  ref.onDispose(subscription.cancel);
});

/// Shows a purchase's message from whatever screen is open.
void _announce(PurchaseOutcome outcome) {
  final context = appScaffoldMessengerKey.currentContext;
  if (context == null || !context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final message = l10n == null ? null : purchaseOutcomeMessage(l10n, outcome);
  if (message != null) ErrorSnackbar.showSuccess(context, message);
}

// Products provider
final productsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  final purchaseService = ref.watch(purchaseServiceProvider);
  if (purchaseService == null) return const [];
  return await purchaseService.getProducts();
});

// Purchase controller state
class PurchaseControllerState {
  final bool isPurchasing;

  const PurchaseControllerState({this.isPurchasing = false});
}

class PurchaseController extends StateNotifier<PurchaseControllerState> {
  final Ref _ref;

  PurchaseController(this._ref) : super(const PurchaseControllerState());

  /// Buys [productId] and completes with what happened, for the caller to show
  /// (showPurchaseOutcome). Never throws: a store error comes back as failed.
  Future<PurchaseOutcome> purchase(String productId) async {
    final purchaseService = _ref.read(purchaseServiceProvider);
    if (purchaseService == null) {
      return PurchaseOutcome(productId, PurchaseOutcomeStatus.failed,
          userInitiated: true);
    }
    state = const PurchaseControllerState(isPurchasing: true);
    try {
      return await purchaseService.purchaseProduct(productId);
    } catch (e) {
      debugPrint('purchase $productId failed: $e');
      return PurchaseOutcome(productId, PurchaseOutcomeStatus.failed,
          userInitiated: true);
    } finally {
      if (mounted) state = const PurchaseControllerState();
    }
  }

  /// Restores past purchases and completes with what each gave; null when the
  /// store couldn't be asked (showRestoreSummary).
  Future<List<PurchaseOutcome>?> restorePurchases() async {
    final purchaseService = _ref.read(purchaseServiceProvider);
    if (purchaseService == null) return null;
    state = const PurchaseControllerState(isPurchasing: true);
    try {
      return await purchaseService.restorePurchases();
    } catch (e) {
      debugPrint('restorePurchases failed: $e');
      return null;
    } finally {
      if (mounted) state = const PurchaseControllerState();
    }
  }
}

final purchaseControllerProvider =
    StateNotifierProvider<PurchaseController, PurchaseControllerState>((ref) {
  return PurchaseController(ref);
});

/// A subscription plan as the shop shows it. The price comes from the store
/// (productsProvider), and the name and perks from l10n (SubscriptionPlanCard).
class SubscriptionPlan {
  final String productId;
  final int dailyTickets;
  final bool isPopular;

  const SubscriptionPlan({
    required this.productId,
    required this.dailyTickets,
    this.isPopular = false,
  });
}

const List<SubscriptionPlan> kSubscriptionPlans = [
  SubscriptionPlan(
    productId: ProductIds.sub500Monthly,
    dailyTickets: AppConstants.dailyTicketsSub500,
  ),
  SubscriptionPlan(
    productId: ProductIds.sub1000Monthly,
    dailyTickets: AppConstants.dailyTicketsSub1000,
    isPopular: true,
  ),
  SubscriptionPlan(
    productId: ProductIds.sub3000Monthly,
    dailyTickets: AppConstants.dailyTicketsSub3000,
  ),
];
