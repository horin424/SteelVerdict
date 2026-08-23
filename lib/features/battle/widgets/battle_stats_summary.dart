import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Short badge for a stat, sized for a small chip.
///
/// Two bugs this replaces, both seen on device:
///   - 'artistry' was missing from the Japanese map, so the row rendered
///     力 / 知 / 技 / 魔 / A / 生 - one Latin letter among five kanji.
///   - The English branch took the first three characters, so a worldview with
///     max_speed and max_altitude showed two chips both reading MAX.
String _statAbbrev(String key, String lang) {
  final k = key.toLowerCase();
  if (lang == 'ja') {
    const ja = {
      'attack': '攻', 'defense': '防', 'speed': '速',
      'morale': '士', 'magic': '魔', 'leadership': '指',
      'wisdom': '知', 'intellect': '知',
      'technology': '技', 'skill': '技',
      'art': '芸', 'artistry': '芸',
      'life': '生', 'strength': '力',
      'luck': '運', 'durability': '耐', 'firepower': '火',
      'maneuverability': '機', 'acceleration': '加',
      'max_speed': '速', 'maxspeed': '速',
      'max_altitude': '高', 'maxaltitude': '高',
    };
    final hit = ja[k];
    if (hit != null) return hit;
    // Unknown key: fall back to the English badge rather than a lone Latin
    // letter, which reads as a typo beside kanji.
    return _asciiAbbrev(k);
  }
  return _asciiAbbrev(k);
}

/// `max_speed` and `maxSpeed` both become `MS`; `strength` becomes `STR`.
///
/// Multi-word keys use initials because truncating to three characters made
/// max_speed and max_altitude collide on `MAX`.
String _asciiAbbrev(String key) {
  final words = key
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAllMapped(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), (_) => ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return key.toUpperCase();
  if (words.length == 1) {
    final w = words.first.toUpperCase();
    return w.substring(0, w.length.clamp(0, 3));
  }
  return words.map((w) => w[0].toUpperCase()).join();
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
