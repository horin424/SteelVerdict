import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../shop_providers.dart';

class SubscriptionPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrentPlan;
  final bool isLoading;
  final VoidCallback onSubscribe;

  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.isCurrentPlan,
    required this.isLoading,
    required this.onSubscribe,
  });

  String _localizedTitle(String productId, AppLocalizations l10n) {
    switch (productId) {
      case 'strategy_game_sub_500_monthly': return l10n.subscriptionCommander;
      case 'strategy_game_sub_1000_monthly': return l10n.subscriptionGeneral;
      case 'strategy_game_sub_3000_monthly': return l10n.subscriptionWarlord;
      default: return plan.title;
    }
  }

  List<String> _localizedFeatures(String productId, AppLocalizations l10n) {
    switch (productId) {
      case 'strategy_game_sub_500_monthly':
        return [
          l10n.shopFeature10Tickets,
          l10n.shopFeatureBasicScenarios,
          l10n.shopFeatureSave20Strategies,
          l10n.shopFeaturePriorityQueue,
        ];
      case 'strategy_game_sub_1000_monthly':
        return [
          l10n.shopFeature20Tickets,
          l10n.shopFeatureEpicMode,
          l10n.shopFeatureUnlimitedHistory,
          l10n.shopFeatureSave50Strategies,
          l10n.shopFeatureAllCommanderFeatures,
        ];
      case 'strategy_game_sub_3000_monthly':
        return [
          l10n.shopFeature50Tickets,
          l10n.shopFeatureAllModes,
          l10n.shopFeatureBossBattles,
          l10n.shopFeatureUnlimitedAll,
          l10n.shopFeatureAllGeneralFeatures,
        ];
      default: return plan.features;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: plan.isPopular
            ? AppColors.goldAccent.withValues(alpha: 0.08)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: plan.isPopular
              ? AppColors.goldAccent
              : isCurrentPlan
                  ? AppColors.victoryGreen
                  : AppColors.borderColor,
          width: plan.isPopular || isCurrentPlan ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (plan.isPopular)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.shopMostPopular,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.inkBrown,
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    Text(_localizedTitle(plan.productId, l10n), style: AppTextStyles.headlineMedium),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.price,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.goldAccent,
                    ),
                  ),
                  Text(
                    l10n.shopTicketsPerDay(plan.dailyTickets),
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),

          // Features
          ..._localizedFeatures(plan.productId, l10n).map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.check, color: AppColors.victoryGreen, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(feature, style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          )),
          const SizedBox(height: 16),

          // Subscribe button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrentPlan || isLoading ? null : onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.isPopular ? AppColors.goldAccent : AppColors.navyLight,
                foregroundColor: plan.isPopular ? AppColors.inkBrown : AppColors.parchmentBeige,
                disabledBackgroundColor: AppColors.textMuted,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isCurrentPlan ? l10n.settingsCurrentPlan : l10n.shopSubscribe),
            ),
          ),
        ],
      ),
    );
  }
}
