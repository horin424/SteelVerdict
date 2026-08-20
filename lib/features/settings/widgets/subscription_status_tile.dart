import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/user_model.dart';

class SubscriptionStatusTile extends StatelessWidget {
  final SubscriptionTier tier;
  final VoidCallback? onUpgrade;

  const SubscriptionStatusTile({
    super.key,
    required this.tier,
    this.onUpgrade,
  });

  Color _tierColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return AppColors.textMuted;
      case SubscriptionTier.sub500:
        return AppColors.goldAccent;
      case SubscriptionTier.sub1000:
        return Colors.orange;
      case SubscriptionTier.sub3000:
        return AppColors.warRedBright;
    }
  }

  String _tierDisplayName(SubscriptionTier tier, AppLocalizations l10n) {
    switch (tier) {
      case SubscriptionTier.free: return l10n.subscriptionFree;
      case SubscriptionTier.sub500: return l10n.subscriptionCommanderPrice;
      case SubscriptionTier.sub1000: return l10n.subscriptionGeneralPrice;
      case SubscriptionTier.sub3000: return l10n.subscriptionWarlordPrice;
    }
  }

  IconData _tierIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Icons.person_outline;
      case SubscriptionTier.sub500:
        return Icons.military_tech;
      case SubscriptionTier.sub1000:
        return Icons.star;
      case SubscriptionTier.sub3000:
        return Icons.local_fire_department;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(tier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyMid,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Icon(_tierIcon(tier), color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.settingsCurrentPlan, style: AppTextStyles.labelSmall),
                Text(_tierDisplayName(tier, AppLocalizations.of(context)!), style: AppTextStyles.headlineSmall.copyWith(color: color)),
              ],
            ),
          ),
          if (tier == SubscriptionTier.free && onUpgrade != null)
            TextButton(
              onPressed: onUpgrade,
              child: Text(
                AppLocalizations.of(context)!.settingsUpgrade,
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.goldAccent),
              ),
            ),
        ],
      ),
    );
  }
}
