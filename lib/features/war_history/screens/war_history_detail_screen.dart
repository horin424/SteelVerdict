import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/battle_record_model.dart';
import '../war_history_providers.dart';
import '../widgets/parchment_render_widget.dart';
import '../../../features/battle/widgets/battle_report_display.dart';
import '../../../features/game_mode_selection/game_mode_providers.dart';

class WarHistoryDetailScreen extends ConsumerStatefulWidget {
  final String recordId;

  const WarHistoryDetailScreen({super.key, required this.recordId});

  @override
  ConsumerState<WarHistoryDetailScreen> createState() =>
      _WarHistoryDetailScreenState();
}

class _WarHistoryDetailScreenState
    extends ConsumerState<WarHistoryDetailScreen> {
  final _parchmentKey = GlobalKey();
  BattleRecordModel? _record;
  bool _loadFinished = false;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final records = await ref.read(battleRecordsProvider.future);
    final record = records.where((r) => r.id == widget.recordId).firstOrNull;
    if (mounted) {
      setState(() {
        _record = record;
        _loadFinished = true;
      });
    }
  }

  String _outcomeFullLabel(BattleOutcome outcome, AppLocalizations l10n) {
    switch (outcome) {
      case BattleOutcome.win:
        return l10n.battleVictoryFull;
      case BattleOutcome.loss:
        return l10n.battleDefeatFull;
      case BattleOutcome.draw:
        return l10n.battleDrawFull;
    }
  }

  String _gameModeLabel(GameMode mode, AppLocalizations l10n) {
    switch (mode) {
      case GameMode.normal:
        return l10n.gameModeNormal;
      case GameMode.tabletop:
        return l10n.gameModeTabletop;
      case GameMode.epic:
        return l10n.gameModeEpic;
      case GameMode.boss:
        return l10n.gameModeBoss;
      case GameMode.practice:
        return l10n.gameModePractice;
    }
  }

  Future<void> _generateAndShare() async {
    if (_record == null) return;

    final controller = ref.read(warHistoryControllerProvider.notifier);
    final history = await controller.generateWarChronicle(_record!);

    if (history != null && mounted) {
      ErrorSnackbar.showSuccess(
        context,
        AppLocalizations.of(context)!.warChronicleGenerated,
      );
    } else if (mounted) {
      final state = ref.read(warHistoryControllerProvider);
      if (state.error != null) {
        ErrorSnackbar.showError(context, state.error!);
      }
    }
  }

  Future<XFile?> _captureImage() async {
    try {
      final boundary =
          _parchmentKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      return XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: 'war_chronicle.png',
      );
    } catch (e) {
      debugPrint('Image capture error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(warHistoryControllerProvider);
    final warHistoriesAsync = ref.watch(warHistoriesProvider);
    final ticketCosts = ref.watch(ticketCostsProvider);

    if (_record == null) {
      // Show loading only if we haven't finished loading yet.
      // If _loadFinished but record is null → not found.
      return Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.warHistoryBattleDetail,
            style: AppTextStyles.headlineMedium,
          ),
        ),
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: _loadFinished
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.history_edu_outlined,
                      color: AppColors.textMuted,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.warHistoryBattleNotFound,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                )
              : const CircularProgressIndicator(color: AppColors.goldAccent),
        ),
      );
    }

    final record = _record!;
    final warHistory = warHistoriesAsync.maybeWhen(
      data: (histories) =>
          histories.where((h) => h.sourceRecordId == record.id).firstOrNull,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.warHistoryBattleDetail,
          style: AppTextStyles.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: Icon(
              record.isFavorite ? Icons.star : Icons.star_outline,
              color: record.isFavorite
                  ? AppColors.goldAccent
                  : AppColors.textMuted,
            ),
            onPressed: () async {
              final controller = ref.read(
                warHistoryControllerProvider.notifier,
              );
              await controller.toggleFavorite(record);
              await _loadRecord();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Outcome banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: record.outcomeEnum == BattleOutcome.win
                    ? AppColors.victoryGreen.withValues(alpha: 0.1)
                    : record.outcomeEnum == BattleOutcome.loss
                    ? AppColors.warRed.withValues(alpha: 0.1)
                    : AppColors.drawGray.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: record.outcomeEnum == BattleOutcome.win
                      ? AppColors.victoryGreen
                      : record.outcomeEnum == BattleOutcome.loss
                      ? AppColors.warRed
                      : AppColors.drawGray,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _outcomeFullLabel(
                      record.outcomeEnum,
                      AppLocalizations.of(context)!,
                    ),
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: record.outcomeEnum == BattleOutcome.win
                          ? AppColors.victoryGreen
                          : record.outcomeEnum == BattleOutcome.loss
                          ? AppColors.warRedBright
                          : AppColors.drawGray,
                    ),
                  ),
                  Text(
                    '${_gameModeLabel(record.gameModeEnum, AppLocalizations.of(context)!)} • ${record.scenarioId}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI Report
            Text(
              AppLocalizations.of(context)!.warHistoryBattleReport,
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 8),
            BattleReportDisplay(reportText: record.aiReport),
            const SizedBox(height: 24),

            // War Chronicle section
            Text(
              AppLocalizations.of(context)!.warHistoryWarChronicle,
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 8),

            if (warHistory != null) ...[
              ParchmentRenderWidget(
                repaintKey: _parchmentKey,
                title: warHistory.title,
                narrative: warHistory.longNarrative,
                outcome: _outcomeFullLabel(
                  record.outcomeEnum,
                  AppLocalizations.of(context)!,
                ),
                date: record.createdAt,
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navyMid,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.history_edu_outlined,
                      color: AppColors.textMuted,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.warHistoryGenerateDesc,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: AppLocalizations.of(context)!.warHistoryGenerate,
                      isLoading: historyState.isGenerating,
                      onPressed: _generateAndShare,
                      icon: Icons.auto_stories,
                      ticketCost: ticketCosts['epic'] ?? 3,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
