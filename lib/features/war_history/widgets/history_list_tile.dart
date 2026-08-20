import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/battle_record_model.dart';

class HistoryListTile extends StatelessWidget {
  final BattleRecordModel record;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const HistoryListTile({
    super.key,
    required this.record,
    required this.onTap,
    required this.onToggleFavorite,
  });

  String _outcomeLabel(BattleOutcome outcome, AppLocalizations l10n) {
    switch (outcome) {
      case BattleOutcome.win: return l10n.battleResultVictory;
      case BattleOutcome.loss: return l10n.battleResultDefeat;
      case BattleOutcome.draw: return l10n.battleResultDraw;
    }
  }

  String _gameModeLabel(GameMode mode, AppLocalizations l10n) {
    switch (mode) {
      case GameMode.normal: return l10n.gameModeNormal;
      case GameMode.tabletop: return l10n.gameModeTabletop;
      case GameMode.epic: return l10n.gameModeEpic;
      case GameMode.boss: return l10n.gameModeBoss;
      case GameMode.practice: return l10n.gameModePractice;
    }
  }

  Color _outcomeColor(BattleOutcome outcome) {
    switch (outcome) {
      case BattleOutcome.win:
        return AppColors.victoryGreen;
      case BattleOutcome.loss:
        return AppColors.warRedBright;
      case BattleOutcome.draw:
        return AppColors.drawGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final outcome = record.outcomeEnum;
    final outcomeColor = _outcomeColor(outcome);

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: record.isFavorite ? AppColors.goldAccent : AppColors.borderColor,
            ),
          ),
          child: Row(
            children: [
              // Outcome indicator
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: outcomeColor,
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
                            record.scenarioTitle.isNotEmpty
                                ? record.scenarioTitle
                                : record.scenarioId,
                            style: AppTextStyles.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: outcomeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: outcomeColor),
                          ),
                          child: Text(
                            _outcomeLabel(outcome, l10n),
                            style: AppTextStyles.labelSmall.copyWith(color: outcomeColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _gameModeLabel(record.gameModeEnum, l10n),
                          style: AppTextStyles.labelSmall,
                        ),
                        const SizedBox(width: 8),
                        const Text('·', style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                        Text(
                          GameDateUtils.timeAgo(record.createdAt),
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Favorite toggle
              IconButton(
                icon: Icon(
                  record.isFavorite ? Icons.star : Icons.star_outline,
                  color: record.isFavorite ? AppColors.goldAccent : AppColors.textMuted,
                  size: 20,
                ),
                onPressed: onToggleFavorite,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
