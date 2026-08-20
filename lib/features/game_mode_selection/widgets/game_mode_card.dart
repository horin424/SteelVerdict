import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class GameModeCard extends StatelessWidget {
  final String modeKey;
  final String title;
  final String description;
  final IconData icon;
  final int ticketCost;
  final bool isSelected;
  final bool isLocked;
  final String? lockReason;
  final VoidCallback onTap;

  const GameModeCard({
    super.key,
    required this.modeKey,
    required this.title,
    required this.description,
    required this.icon,
    required this.ticketCost,
    required this.isSelected,
    required this.onTap,
    this.isLocked = false,
    this.lockReason,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: Material(
        color: isSelected ? AppColors.goldAccent.withValues(alpha: 0.15) : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.goldAccent : AppColors.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.goldAccent.withValues(alpha: 0.2)
                        : AppColors.navyMid,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.goldAccent : AppColors.borderColor,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: isSelected ? AppColors.goldAccent : AppColors.parchmentBeige,
                            ),
                          ),
                          if (isLocked) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.lock, size: 14, color: AppColors.textMuted),
                          ],
                        ],
                      ),
                      Text(
                        isLocked ? (lockReason ?? l10n.gameModeLocked) : description,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Ticket cost badge
                Column(
                    children: [
                      if (ticketCost == 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.victoryGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.victoryGreen),
                          ),
                          child: Text(
                            l10n.gameModeFree,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.victoryGreen,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.goldAccent),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.confirmation_number, size: 12, color: AppColors.goldAccent),
                              const SizedBox(width: 2),
                              Text(
                                '$ticketCost',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.goldAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: const Icon(
                            Icons.check_circle,
                            color: AppColors.goldAccent,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
