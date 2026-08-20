import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/scenario_model.dart';
import '../../../core/l10n/app_localizations.dart';

class ScenarioCard extends StatelessWidget {
  final ScenarioModel scenario;
  final VoidCallback onTap;
  final VoidCallback? onUnlock;

  const ScenarioCard({
    super.key,
    required this.scenario,
    required this.onTap,
    this.onUnlock,
  });

  String _difficultyLabel(int difficulty, AppLocalizations l10n) {
    switch (difficulty) {
      case 1: return l10n.difficultyNovice;
      case 2: return l10n.difficultySoldier;
      case 3: return l10n.difficultyCaptain;
      case 4: return l10n.difficultyGeneral;
      case 5: return l10n.difficultyWarlord;
      default: return l10n.difficultyUnknown;
    }
  }

  Color _difficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return AppColors.victoryGreen;
      case 2:
        return Colors.teal;
      case 3:
        return AppColors.goldAccent;
      case 4:
        return Colors.orange;
      case 5:
        return AppColors.warRedBright;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final isLocked = !scenario.isUnlocked && !scenario.isFree;
    final diffColor = _difficultyColor(scenario.difficulty);

    return Opacity(
      opacity: isLocked ? 0.7 : 1.0,
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: isLocked ? onUnlock : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isLocked ? AppColors.textMuted : AppColors.borderColor,
              ),
            ),
            child: Row(
              children: [
                // Difficulty indicator
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isLocked ? AppColors.textMuted : diffColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              scenario.localizedTitle(lang),
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: isLocked ? AppColors.textMuted : AppColors.parchmentBeige,
                              ),
                            ),
                          ),
                          if (scenario.isFree)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.victoryGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.victoryGreen),
                              ),
                              child: Text(
                                l10n.scenarioFree,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.victoryGreen,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.scenarioVsEnemy(scenario.localizedEnemyName(lang)),
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.whatshot, size: 12, color: diffColor),
                          const SizedBox(width: 4),
                          Text(
                            _difficultyLabel(scenario.difficulty, l10n),
                            style: AppTextStyles.labelSmall.copyWith(color: diffColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Lock indicator
                if (isLocked)
                  const Icon(Icons.lock, color: AppColors.textMuted, size: 20)
                else
                  const Icon(Icons.arrow_forward_ios, color: AppColors.goldAccent, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
