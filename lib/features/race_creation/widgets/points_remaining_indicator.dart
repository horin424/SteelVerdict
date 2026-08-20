import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/l10n/app_localizations.dart';

class PointsRemainingIndicator extends StatelessWidget {
  final int used;
  final int total;

  const PointsRemainingIndicator({
    super.key,
    required this.used,
    required this.total,
  });

  int get remaining => total - used;
  double get fraction => total > 0 ? (used / total).clamp(0.0, 1.0) : 0;

  Color get barColor {
    if (fraction >= 1.0) return AppColors.warRed;
    if (fraction >= 0.7) return AppColors.goldAccent;
    return AppColors.victoryGreen;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyMid,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: remaining == 0 ? AppColors.warRed : AppColors.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.raceStatPoints, style: AppTextStyles.labelLarge),
              Row(
                children: [
                  Text(
                    '$used',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: barColor,
                    ),
                  ),
                  Text(
                    ' / $total',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remaining > 0
                ? l10n.raceCreationPointsRemaining(remaining)
                : remaining == 0
                    ? l10n.raceAllAllocated
                    : l10n.raceOverLimit,
            style: AppTextStyles.bodySmall.copyWith(
              color: remaining > 0
                  ? AppColors.textSecondary
                  : remaining == 0
                      ? AppColors.victoryGreen
                      : AppColors.warRed,
            ),
          ),
        ],
      ),
    );
  }
}
