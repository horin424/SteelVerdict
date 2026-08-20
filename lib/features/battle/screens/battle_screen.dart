import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../features/home/home_providers.dart';
import '../../../features/scenario_selection/scenario_providers.dart';
import '../../../features/splash/splash_providers.dart';
import '../../../models/user_model.dart';
import '../battle_providers.dart';
import '../../../services/sound/sound_service_provider.dart';
import '../widgets/strategy_input_field.dart';
import '../widgets/saved_strategies_picker.dart';
import '../widgets/battle_stats_summary.dart';
import '../widgets/general_staff_overlay.dart';

String _localizedGameMode(String mode, String lang) {
  if (lang != 'ja') return mode.toUpperCase();
  const ja = {
    'practice': '練習',
    'tabletop': 'テーブルトップ',
    'normal': '通常',
    'epic': '叙事詩',
    'boss': 'ボス',
    'history_puzzle': '歴史パズル',
    'pvp': 'PvP',
  };
  return ja[mode] ?? mode.toUpperCase();
}

class BattleScreen extends ConsumerStatefulWidget {
  final String scenarioId;
  final String gameMode;

  const BattleScreen({
    super.key,
    required this.scenarioId,
    required this.gameMode,
  });

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  final _strategyController = TextEditingController();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(soundServiceProvider).playBgm('bgm_battle.mp3');
    });
  }

  @override
  void dispose() {
    _strategyController.dispose();
    ref.read(soundServiceProvider).stopBgm();
    super.dispose();
  }

  Future<void> _saveCurrentStrategy() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _strategyController.text.trim();
    if (text.isEmpty) return;

    // Check tier limit
    final storageService = ref.read(hiveStorageServiceProvider);
    final existing = storageService.getStrategies();
    final userAsync = ref.read(currentUserModelProvider);
    final tier = userAsync.valueOrNull?.subscriptionTier;
    final limit = tier == null || tier == SubscriptionTier.free
        ? 1
        : tier == SubscriptionTier.sub500
            ? 3
            : null; // null = unlimited

    if (limit != null && existing.length >= limit) {
      ErrorSnackbar.showError(context, l10n.battleSaveStrategyLimitReached);
      return;
    }

    final nameController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navyMid,
        title: Text(l10n.battleSaveStrategyDialogTitle, style: AppTextStyles.headlineSmall),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(hintText: l10n.battleSaveStrategyNameHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save, style: const TextStyle(color: AppColors.goldAccent)),
          ),
        ],
      ),
    );
    final strategyName = nameController.text.trim();
    nameController.dispose();

    if (saved == true && strategyName.isNotEmpty && mounted) {
      await storageService.saveStrategy(strategyName, text);
      if (mounted) ErrorSnackbar.showSuccess(context, l10n.battleSaveStrategySuccess);
    }
  }

  Future<void> _submit() async {
    final error = Validators.validateStrategyText(_strategyController.text, l10n: AppLocalizations.of(context));
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }
    setState(() => _validationError = null);
    await _runBattle(_strategyController.text);
  }

  Future<void> _runBattle(String strategy) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(battleControllerProvider.notifier);
    final result = await controller.submitBattle(
      scenarioId: widget.scenarioId,
      gameMode: widget.gameMode,
      strategy: strategy,
    );

    if (!mounted) return;

    final state = ref.read(battleControllerProvider);

    if (result != null) {
      context.push(
        RouteNames.battleResult,
        extra: {
          'reportText': result.reportText,
          'outcome': result.outcome,
          'shortSummary': result.shortSummary,
          'scenarioId': widget.scenarioId,
          'gameMode': widget.gameMode,
        },
      );
    } else if (state.showAdChoice) {
      // Practice mode ad choice — show dialog
      _showAdChoiceDialog(strategy);
    } else if (state.errorMessage != null) {
      final raw = state.errorMessage!;
      final String msg;
      if (raw == 'content_filter_blocked') {
        msg = l10n.contentFilterBlocked;
      } else if (raw == 'battle_failed_retry') {
        msg = l10n.battleFailedRetry;
      } else if (raw == 'battle_sign_in_required') {
        msg = l10n.battleSignInRequired;
      } else {
        msg = raw;
      }
      ErrorSnackbar.showError(context, msg);
    }
  }

  void _showAdChoiceDialog(String strategy) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navyMid,
        title: Text(l10n.practiceAdPrompt, style: AppTextStyles.headlineSmall),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.play_circle_outline, color: AppColors.goldAccent),
            label: Text(l10n.watchAdFree),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(battleControllerProvider.notifier).watchPracticeAd();
              if (mounted) await _runBattle(strategy);
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.skip_next_outlined, color: AppColors.textMuted),
            label: Text(l10n.skipAdCost, style: const TextStyle(color: AppColors.textMuted)),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(battleControllerProvider.notifier).skipPracticeAd();
              if (mounted) await _runBattle(strategy);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final battleState = ref.watch(battleControllerProvider);
    final race = ref.watch(currentRaceProvider);
    final scenarios = ref.watch(scenariosProvider);
    final scenario = scenarios.where((s) => s.scenarioId == widget.scenarioId).firstOrNull;

    final lang = Localizations.localeOf(context).languageCode;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.darkBackground,
          appBar: AppBar(
            title: Text(
              scenario?.localizedTitle(lang) ?? l10n.battleTitle,
              style: AppTextStyles.headlineMedium,
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Scenario info
                if (scenario != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.navyMid,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.battleEnemyLabel(scenario.localizedEnemyName(lang)),
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.warRed,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scenario.localizedCommanderDefinition(lang),
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.battleModeLabel(_localizedGameMode(widget.gameMode, lang)),
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // Race stats
                if (race != null)
                  BattleStatsSummary(
                    raceName: race.raceName,
                    stats: race.stats,
                  ),
                const SizedBox(height: 16),

                // Strategy input
                StrategyInputField(
                  controller: _strategyController,
                  errorText: _validationError,
                  enabled: !battleState.isSubmitting,
                ),
                const SizedBox(height: 8),

                // Load / Save saved strategies
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        SavedStrategiesPicker.show(
                          context,
                          onSelected: (text) {
                            _strategyController.text = text;
                          },
                        );
                      },
                      icon: const Icon(Icons.folder_open_outlined, size: 16),
                      label: Text(l10n.battleLoadSaved),
                    ),
                    TextButton.icon(
                      onPressed: _saveCurrentStrategy,
                      icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                      label: Text(l10n.battleSaveStrategy),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Submit button
                ElevatedButton(
                  onPressed: battleState.isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: battleState.isSubmitting
                      ? const CircularProgressIndicator()
                      : Text(
                          l10n.battleSubmit,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.inkBrown,
                          ),
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        // Animated overlay for tabletop mode with Watch Ad / Skip buttons
        GeneralStaffOverlay(
          isVisible: battleState.isSubmitting && widget.gameMode == 'tabletop',
          onWatchAd: widget.gameMode == 'tabletop'
              ? () async {
                  final adService = ref.read(adServiceProvider);
                  await adService.loadInterstitialAd();
                  await adService.showInterstitialAd();
                }
              : null,
          onSkip: widget.gameMode == 'tabletop'
              ? () async {
                  await ref.read(battleControllerProvider.notifier).skipTabletopAd();
                }
              : null,
        ),
      ],
    );
  }
}
