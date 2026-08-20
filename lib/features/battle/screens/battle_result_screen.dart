import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../widgets/battle_report_display.dart';
import '../../../services/sound/sound_service_provider.dart';

class BattleResultScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? resultData;

  const BattleResultScreen({super.key, this.resultData});

  @override
  ConsumerState<BattleResultScreen> createState() => _BattleResultScreenState();
}

class _BattleResultScreenState extends ConsumerState<BattleResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final outcome = (widget.resultData?['outcome'] as String? ?? '').toLowerCase();
      final sound = ref.read(soundServiceProvider);
      sound.stopBgm();
      if (outcome == 'win' || outcome == 'victory') {
        sound.playVictory();
      } else if (outcome == 'loss' || outcome == 'defeat') {
        sound.playDefeat();
      }
    });
  }

  Color _outcomeColor(String outcome) {
    switch (outcome.toLowerCase()) {
      case 'win':
      case 'victory':
        return AppColors.victoryGreen;
      case 'loss':
      case 'defeat':
        return AppColors.warRedBright;
      default:
        return AppColors.drawGray;
    }
  }

  String _outcomeLabel(String outcome, AppLocalizations l10n) {
    switch (outcome.toLowerCase()) {
      case 'win':
        return l10n.battleVictoryFull;
      case 'loss':
        return l10n.battleDefeatFull;
      default:
        return l10n.battleDrawFull;
    }
  }

  IconData _outcomeIcon(String outcome) {
    switch (outcome.toLowerCase()) {
      case 'win':
        return Icons.emoji_events;
      case 'loss':
        return Icons.flag_outlined;
      default:
        return Icons.balance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final outcome = widget.resultData?['outcome'] as String? ?? 'draw';
    final reportText = widget.resultData?['reportText'] as String? ?? l10n.battleNoReport;
    final shortSummary = widget.resultData?['shortSummary'] as String? ?? '';

    final outcomeColor = _outcomeColor(outcome);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(l10n.battleResultTitle, style: AppTextStyles.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go(RouteNames.home),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Outcome banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: outcomeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: outcomeColor, width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    _outcomeIcon(outcome),
                    color: outcomeColor,
                    size: 56,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _outcomeLabel(outcome, l10n),
                    style: AppTextStyles.displaySmall.copyWith(
                      color: outcomeColor,
                      letterSpacing: 4,
                    ),
                  ),
                  if (shortSummary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        shortSummary,
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Report
            Text(l10n.battleReport, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            BattleReportDisplay(reportText: reportText),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ErrorSnackbar.showSuccess(context, AppLocalizations.of(context)!.battleSavedToHistory);
                    },
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(l10n.save),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(RouteNames.battleType),
                    icon: const Icon(Icons.replay, size: 18),
                    label: Text(l10n.battlePlayAgain),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push(RouteNames.warHistory),
              icon: const Icon(Icons.history_edu_outlined, size: 18),
              label: Text(l10n.battleViewWarHistory),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
