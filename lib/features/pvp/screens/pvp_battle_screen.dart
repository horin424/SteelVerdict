import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../features/auth/auth_providers.dart';
import '../pvp_providers.dart';
import '../widgets/opponent_stats_panel.dart';
import '../widgets/pvp_countdown_timer.dart';
import '../../../models/pvp_match_model.dart';

class PvpBattleScreen extends ConsumerStatefulWidget {
  final String matchId;

  const PvpBattleScreen({super.key, required this.matchId});

  @override
  ConsumerState<PvpBattleScreen> createState() => _PvpBattleScreenState();
}

class _PvpBattleScreenState extends ConsumerState<PvpBattleScreen> {
  final _strategyController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _strategyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = Validators.validateStrategyText(_strategyController.text, l10n: AppLocalizations.of(context));
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }
    setState(() => _validationError = null);

    final controller = ref.read(pvpBattleControllerProvider.notifier);
    final success = await controller.submitStrategy(
      widget.matchId,
      _strategyController.text,
    );

    if (success && mounted) {
      ErrorSnackbar.showSuccess(
        context,
        AppLocalizations.of(context)!.pvpStrategySubmitted,
      );
    } else if (mounted) {
      final state = ref.read(pvpBattleControllerProvider);
      if (state.error != null) {
        ErrorSnackbar.showError(context, state.error!);
      }
    }
  }

  String _pvpStatusLabel(PvpMatchStatus status, AppLocalizations l10n) {
    switch (status) {
      case PvpMatchStatus.waiting: return l10n.pvpStatusWaiting;
      case PvpMatchStatus.active: return l10n.pvpStatusActive;
      case PvpMatchStatus.resolved: return l10n.pvpStatusResolved;
      case PvpMatchStatus.timeout: return l10n.pvpStatusTimedOut;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pvpState = ref.watch(pvpBattleControllerProvider);
    final authState = ref.watch(authStateChangesProvider);
    final currentUid = authState.valueOrNull?.uid ?? '';

    // Watch the specific match
    final firestoreService = ref.read(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pvpBattleTitle, style: AppTextStyles.headlineMedium),
      ),
      body: StreamBuilder(
        stream: firestoreService.watchPvpMatch(widget.matchId),
        builder: (context, snapshot) {
          final match = snapshot.data;

          if (match == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.goldAccent),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.pvpLoadingMatch, style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }

          final isPlayerA = match.playerAUid == currentUid;
          final hasSubmitted = match.hasPlayerSubmitted(currentUid);
          final opponentStats = isPlayerA ? match.playerBStats : match.playerAStats;
          final l10n = AppLocalizations.of(context)!;
          final opponentName = isPlayerA
              ? (match.playerBRaceName.isEmpty ? l10n.pvpOpponent : match.playerBRaceName)
              : match.playerARaceName;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Match info
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l10n.pvpMatchPrefix} #${widget.matchId.substring(0, 8).toUpperCase()}',
                        style: AppTextStyles.headlineSmall,
                      ),
                    ),
                    PvpCountdownTimer(expiresAt: match.expiresAt),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.pvpStatusPrefix}: ${_pvpStatusLabel(match.status, l10n)}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),

                // Opponent stats
                if (opponentStats.isNotEmpty)
                  OpponentStatsPanel(
                    opponentName: opponentName,
                    stats: opponentStats,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.navyMid,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_empty, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.pvpWaitingOpponent, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Strategy submission
                if (hasSubmitted || pvpState.isSubmitted) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.victoryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.victoryGreen),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.victoryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.pvpStrategySubmitted,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(AppLocalizations.of(context)!.pvpYourStrategy, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.navyMid,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _validationError != null
                            ? AppColors.warRedBright
                            : AppColors.borderColor,
                      ),
                    ),
                    child: TextField(
                      controller: _strategyController,
                      maxLines: 8,
                      style: AppTextStyles.bodyMedium,
                      enabled: !pvpState.isSubmitting,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.pvpStrategyHint,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        hintStyle: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  if (_validationError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _validationError!,
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.warRedBright),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: pvpState.isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: pvpState.isSubmitting
                        ? const CircularProgressIndicator()
                        : Text(AppLocalizations.of(context)!.pvpSubmitStrategy),
                  ),
                ],

                if (match.status == PvpMatchStatus.resolved) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.navyMid,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.goldAccent),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.pvpBattleResultLabel, style: AppTextStyles.headlineSmall),
                        const SizedBox(height: 8),
                        Text(match.shortReport, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 8),
                        Text(
                          match.winner == currentUid
                              ? AppLocalizations.of(context)!.pvpYouWon
                              : match.winner == 'draw'
                                  ? AppLocalizations.of(context)!.pvpDraw
                                  : AppLocalizations.of(context)!.pvpOpponentWon,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: match.winner == currentUid
                                ? AppColors.victoryGreen
                                : match.winner == 'draw'
                                    ? AppColors.drawGray
                                    : AppColors.warRedBright,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
