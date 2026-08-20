import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class DailyRewardButton extends StatelessWidget {
  final bool isAvailable;
  final bool isLoading;
  final VoidCallback? onClaim;

  const DailyRewardButton({
    super.key,
    required this.isAvailable,
    required this.onClaim,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.goldAccent.withValues(alpha: 0.15) : AppColors.navyMid,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAvailable ? AppColors.goldAccent : AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAvailable && !isLoading ? onClaim : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: isAvailable ? AppColors.goldAccent : AppColors.textMuted,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeDailyReward,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: isAvailable ? AppColors.goldAccent : AppColors.textMuted,
                        ),
                      ),
                      Text(
                        isAvailable ? l10n.dailyRewardAvailable : l10n.dailyRewardComeBack,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (isAvailable)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.dailyClaim,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.inkBrown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.check_circle, color: AppColors.victoryGreen, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
