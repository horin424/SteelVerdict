import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/stat_bar.dart';

class OpponentStatsPanel extends StatelessWidget {
  final String opponentName;
  final Map<String, int> stats;

  const OpponentStatsPanel({
    super.key,
    required this.opponentName,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.navyMid,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          children: [
            const Icon(Icons.person_outline, color: AppColors.textMuted, size: 32),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.pvpOpponentStatsHidden, style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    final maxStat = stats.values.isEmpty ? 10 : stats.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyMid,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.warRed, size: 16),
              const SizedBox(width: 6),
              Text(opponentName, style: AppTextStyles.headlineSmall),
            ],
          ),
          const SizedBox(height: 12),
          ...stats.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: StatBar(
              label: e.key,
              value: e.value,
              maxValue: maxStat > 0 ? maxStat : 10,
              barColor: AppColors.warRed.withValues(alpha: 0.8),
            ),
          )),
        ],
      ),
    );
  }
}
