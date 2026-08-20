import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

String _statAbbrev(String key, String lang) {
  if (lang == 'ja') {
    const ja = {
      'attack': '攻', 'defense': '防', 'speed': '速',
      'morale': '士', 'magic': '魔', 'leadership': '指',
      'wisdom': '知', 'technology': '技', 'art': '芸', 'life': '生', 'strength': '力',
    };
    return ja[key.toLowerCase()] ?? key.substring(0, 1).toUpperCase();
  }
  return key.toUpperCase().substring(0, key.length.clamp(0, 3));
}

class BattleStatsSummary extends StatelessWidget {
  final String raceName;
  final Map<String, int> stats;

  const BattleStatsSummary({
    super.key,
    required this.raceName,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.navyMid,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech, color: AppColors.goldAccent, size: 16),
              const SizedBox(width: 6),
              Text(raceName, style: AppTextStyles.headlineSmall),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: stats.entries.map((entry) {
              final lang = Localizations.localeOf(context).languageCode;
              return _StatChip(label: _statAbbrev(entry.key, lang), value: entry.value);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall,
          ),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.goldAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
