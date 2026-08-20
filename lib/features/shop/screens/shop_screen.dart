import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../models/user_model.dart';
import '../shop_providers.dart';
import '../widgets/subscription_plan_card.dart';
import '../widgets/one_time_purchase_tile.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final purchaseState = ref.watch(purchaseControllerProvider);
    final purchaseController = ref.read(purchaseControllerProvider.notifier);
    final userAsync = ref.watch(currentUserModelProvider);

    final currentTier = userAsync.maybeWhen(
      data: (u) => u?.subscriptionTier ?? SubscriptionTier.free,
      orElse: () => SubscriptionTier.free,
    );

    // Show success/error messages
    ref.listen(purchaseControllerProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        final msg = next.successMessage == 'purchase_initiated'
            ? l10n.shopPurchaseInitiated
            : l10n.shopPurchasesRestored;
        ErrorSnackbar.showSuccess(context, msg);
      }
      if (next.error != null && next.error != prev?.error) {
        final raw = next.error!;
        final String msg;
        if (raw.startsWith('purchase_failed:')) {
          msg = '${l10n.shopPurchaseFailed}: ${raw.substring(16)}';
        } else if (raw.startsWith('restore_failed:')) {
          msg = '${l10n.shopRestoreFailed}: ${raw.substring(15)}';
        } else {
          msg = raw;
        }
        ErrorSnackbar.showError(context, msg);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(l10n.shopTitle, style: AppTextStyles.headlineMedium),
        actions: [
          TextButton(
            onPressed: purchaseState.isPurchasing
                ? null
                : () => purchaseController.restorePurchases(),
            child: Text(
              l10n.shopRestoreShort,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.goldAccent),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subscriptions section
            Text(
              l10n.shopSubscriptions,
              style: AppTextStyles.labelSmall.copyWith(
                letterSpacing: 2,
                color: AppColors.goldAccent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.shopUnlockMore,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            ...kSubscriptionPlans.map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SubscriptionPlanCard(
                plan: plan,
                isCurrentPlan: currentTier.name == _productToTier(plan.productId),
                isLoading: purchaseState.isPurchasing,
                onSubscribe: () => purchaseController.purchase(plan.productId),
              ),
            )),

            const SizedBox(height: 24),

            // One-time purchases section
            Text(
              l10n.shopTicketPacks,
              style: AppTextStyles.labelSmall.copyWith(
                letterSpacing: 2,
                color: AppColors.goldAccent,
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.shopOneTimePurchases, style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),

            OneTimePurchaseTile(
              productId: 'strategy_game_tickets_10',
              title: l10n.shopSmallPack,
              subtitle: l10n.shopSmallPackDesc,
              price: '¥240',
              icon: Icons.confirmation_number,
              isLoading: purchaseState.isPurchasing,
              onPurchase: () => purchaseController.purchase('strategy_game_tickets_10'),
            ),
            OneTimePurchaseTile(
              productId: 'strategy_game_tickets_30',
              title: l10n.shopLargePack,
              subtitle: l10n.shopLargePackDesc,
              price: '¥600',
              icon: Icons.confirmation_number_outlined,
              isLoading: purchaseState.isPurchasing,
              onPurchase: () => purchaseController.purchase('strategy_game_tickets_30'),
            ),

            const SizedBox(height: 24),

            // Scenario packs section
            Text(
              l10n.shopScenarioPacks,
              style: AppTextStyles.labelSmall.copyWith(
                letterSpacing: 2,
                color: AppColors.goldAccent,
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.shopScenarioPacksDesc, style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),

            OneTimePurchaseTile(
              productId: 'strategy_game_scenario_pack_1',
              title: l10n.shopAncientBattles,
              subtitle: l10n.shopAncientBattlesDesc,
              price: '¥480',
              icon: Icons.map_outlined,
              isLoading: purchaseState.isPurchasing,
              onPurchase: () => purchaseController.purchase('strategy_game_scenario_pack_1'),
            ),

            const SizedBox(height: 32),

            // Legal text
            Text(
              l10n.shopAutoRenew,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _productToTier(String productId) {
    if (productId.contains('500')) return 'sub500';
    if (productId.contains('1000')) return 'sub1000';
    if (productId.contains('3000')) return 'sub3000';
    return 'free';
  }
}
