import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/legal_links.dart';
import '../../../core/widgets/link_text_button.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../models/user_model.dart';
import '../purchase_messages.dart';
import '../shop_providers.dart';
import '../widgets/subscription_plan_card.dart';
import '../widgets/one_time_purchase_tile.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  /// Buys and then tells the user what the store and the server said. Nothing
  /// is shown before that: "purchase started" used to appear even when the
  /// user closed the store's sheet (B30).
  Future<void> _buy(BuildContext context, WidgetRef ref, String productId) async {
    final outcome = await ref.read(purchaseControllerProvider.notifier).purchase(productId);
    if (context.mounted) showPurchaseOutcome(context, outcome);
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final outcomes = await ref.read(purchaseControllerProvider.notifier).restorePurchases();
    if (context.mounted) showRestoreSummary(context, outcomes);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final purchaseState = ref.watch(purchaseControllerProvider);
    final userAsync = ref.watch(currentUserModelProvider);

    final currentTier = userAsync.maybeWhen(
      data: (u) => u?.subscriptionTier ?? SubscriptionTier.free,
      orElse: () => SubscriptionTier.free,
    );

    // Prices come from the store, in the user's currency. A product the store
    // didn't return has no price and can't be bought.
    final prices = {
      for (final product in ref.watch(productsProvider).valueOrNull ?? const <ProductDetails>[])
        product.id: product.price,
    };

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(l10n.shopTitle, style: AppTextStyles.headlineMedium),
        actions: [
          TextButton(
            onPressed: purchaseState.isPurchasing
                ? null
                : () => _restore(context, ref),
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
                price: prices[plan.productId],
                isCurrentPlan: currentTier.name == _productToTier(plan.productId),
                isLoading: purchaseState.isPurchasing,
                onSubscribe: () => _buy(context, ref, plan.productId),
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
              price: prices['strategy_game_tickets_10'],
              icon: Icons.confirmation_number,
              isLoading: purchaseState.isPurchasing,
              onPurchase: () => _buy(context, ref, 'strategy_game_tickets_10'),
            ),
            OneTimePurchaseTile(
              productId: 'strategy_game_tickets_30',
              title: l10n.shopLargePack,
              subtitle: l10n.shopLargePackDesc,
              price: prices['strategy_game_tickets_30'],
              icon: Icons.confirmation_number_outlined,
              isLoading: purchaseState.isPurchasing,
              onPurchase: () => _buy(context, ref, 'strategy_game_tickets_30'),
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
              price: prices['strategy_game_scenario_pack_1'],
              icon: Icons.map_outlined,
              isLoading: purchaseState.isPurchasing,
              onPurchase: () => _buy(context, ref, 'strategy_game_scenario_pack_1'),
            ),

            const SizedBox(height: 32),

            // Legal text
            Text(
              l10n.shopAutoRenew,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Apple 3.1.2: Terms of Use and Privacy Policy next to subscriptions,
            // and where to cancel them.
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                LinkTextButton(label: l10n.shopTermsOfUse, url: LegalLinks.termsOfUse),
                LinkTextButton(label: l10n.settingsPrivacyPolicy, url: LegalLinks.privacyPolicy),
                LinkTextButton(
                  label: l10n.shopManageSubscriptions,
                  url: LegalLinks.manageSubscriptions,
                ),
              ],
            ),
            const SizedBox(height: 24),
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
