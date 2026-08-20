import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/pvp_match_model.dart';
import '../../../core/utils/date_utils.dart';
import 'pvp_countdown_timer.dart';

class MatchCard extends StatelessWidget {
  final PvpMatchModel match;
  final String currentUid;
  final VoidCallback onTap;

  const MatchCard({
    super.key,
    required this.match,
    required this.currentUid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPlayerA = match.playerAUid == currentUid;
    final myRaceName = isPlayerA ? match.playerARaceName : match.playerBRaceName;
    final opponentRaceName = isPlayerA ? match.playerBRaceName : match.playerARaceName;
    final hasSubmitted = match.hasPlayerSubmitted(currentUid);
    final opponentSubmitted = isPlayerA
        ? match.playerBStrategy.isNotEmpty
        : match.playerAStrategy.isNotEmpty;

    // Determine status banner config
    final _StatusConfig config = _resolveStatus(
      match: match,
      currentUid: currentUid,
      hasSubmitted: hasSubmitted,
      opponentSubmitted: opponentSubmitted,
      l10n: l10n,
    );

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: config.borderColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: config.bannerColor.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Row(
                  children: [
                    Icon(config.icon, color: config.bannerColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        config.statusLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: config.bannerColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (config.actionNeeded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: config.bannerColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ACTION',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: config.bannerColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Match body
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Race name vs opponent
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$myRaceName  vs  ${opponentRaceName.isEmpty ? "???" : opponentRaceName}',
                            style: AppTextStyles.headlineSmall,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Submission status indicators (only for active matches)
                    if (match.status == PvpMatchStatus.active)
                      Row(
                        children: [
                          _SubmitChip(
                            label: 'You',
                            submitted: hasSubmitted,
                          ),
                          const SizedBox(width: 8),
                          _SubmitChip(
                            label: opponentRaceName.isEmpty ? 'Opponent' : opponentRaceName,
                            submitted: opponentSubmitted,
                          ),
                        ],
                      ),

                    const SizedBox(height: 10),

                    // Footer: time ago + countdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          GameDateUtils.timeAgo(match.createdAt),
                          style: AppTextStyles.labelSmall,
                        ),
                        if (match.status == PvpMatchStatus.active ||
                            match.status == PvpMatchStatus.waiting)
                          PvpCountdownTimer(expiresAt: match.expiresAt),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusConfig _resolveStatus({
    required PvpMatchModel match,
    required String currentUid,
    required bool hasSubmitted,
    required bool opponentSubmitted,
    required AppLocalizations l10n,
  }) {
    switch (match.status) {
      case PvpMatchStatus.waiting:
        return _StatusConfig(
          icon: Icons.hourglass_top_rounded,
          statusLabel: l10n.pvpWaitingForOpponent,
          bannerColor: AppColors.goldAccent,
          borderColor: AppColors.goldAccent,
          actionNeeded: false,
        );

      case PvpMatchStatus.active:
        if (!hasSubmitted && opponentSubmitted) {
          // Opponent submitted — urgent!
          return _StatusConfig(
            icon: Icons.notification_important_rounded,
            statusLabel: l10n.pvpOpponentSubmittedUrge,
            bannerColor: AppColors.warRedBright,
            borderColor: AppColors.warRedBright,
            actionNeeded: true,
          );
        } else if (!hasSubmitted) {
          return _StatusConfig(
            icon: Icons.edit_note_rounded,
            statusLabel: l10n.pvpSubmitYourStrategy,
            bannerColor: AppColors.orange,
            borderColor: AppColors.orange,
            actionNeeded: true,
          );
        } else if (!opponentSubmitted) {
          return _StatusConfig(
            icon: Icons.hourglass_bottom_rounded,
            statusLabel: l10n.pvpWaitingForOpponent,
            bannerColor: AppColors.teal,
            borderColor: AppColors.teal,
            actionNeeded: false,
          );
        } else {
          // Both submitted — resolving
          return _StatusConfig(
            icon: Icons.auto_mode_rounded,
            statusLabel: l10n.pvpBothSubmittedResolving,
            bannerColor: AppColors.purple,
            borderColor: AppColors.purple,
            actionNeeded: false,
          );
        }

      case PvpMatchStatus.resolved:
        if (match.winner == currentUid) {
          return _StatusConfig(
            icon: Icons.emoji_events_rounded,
            statusLabel: l10n.pvpVictory,
            bannerColor: AppColors.victoryGreen,
            borderColor: AppColors.victoryGreen,
            actionNeeded: false,
          );
        } else if (match.winner == 'draw') {
          return _StatusConfig(
            icon: Icons.handshake_rounded,
            statusLabel: l10n.pvpDraw,
            bannerColor: AppColors.drawGray,
            borderColor: AppColors.drawGray,
            actionNeeded: false,
          );
        } else {
          return _StatusConfig(
            icon: Icons.shield_outlined,
            statusLabel: l10n.pvpDefeat,
            bannerColor: AppColors.warRed,
            borderColor: AppColors.warRed,
            actionNeeded: false,
          );
        }

      case PvpMatchStatus.timeout:
        return _StatusConfig(
          icon: Icons.timer_off_rounded,
          statusLabel: l10n.pvpTimeout,
          bannerColor: AppColors.textMuted,
          borderColor: AppColors.textMuted,
          actionNeeded: false,
        );
    }
  }
}

class _StatusConfig {
  final IconData icon;
  final String statusLabel;
  final Color bannerColor;
  final Color borderColor;
  final bool actionNeeded;

  const _StatusConfig({
    required this.icon,
    required this.statusLabel,
    required this.bannerColor,
    required this.borderColor,
    required this.actionNeeded,
  });
}

class _SubmitChip extends StatelessWidget {
  final String label;
  final bool submitted;

  const _SubmitChip({required this.label, required this.submitted});

  @override
  Widget build(BuildContext context) {
    final color = submitted ? AppColors.victoryGreen : AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          submitted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: color, fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
