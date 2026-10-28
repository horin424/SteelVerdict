import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../models/scenario_model.dart';
import '../../../services/game_config/game_config_providers.dart';
import '../scenario_providers.dart';

/// Where the player chooses the scenarios the scenario pack unlocks. The choice
/// is saved to the account and is final, so it is confirmed first. Closing the
/// sheet without choosing is fine: the shop and every locked scenario offer
/// the choice again.
class ScenarioPackPicker extends ConsumerStatefulWidget {
  /// Ticked when the sheet opens (the locked scenario the player tapped).
  final String? preselectedId;

  const ScenarioPackPicker({super.key, this.preselectedId});

  /// Shows the picker; completes with true once a choice was saved.
  static Future<bool> show(BuildContext context, {String? preselectedId}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navyMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.borderGold),
      ),
      builder: (ctx) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: ScenarioPackPicker(preselectedId: preselectedId),
      ),
    );
    return saved ?? false;
  }

  @override
  ConsumerState<ScenarioPackPicker> createState() => _ScenarioPackPickerState();
}

class _ScenarioPackPickerState extends ConsumerState<ScenarioPackPicker> {
  final _picked = <String>{};

  @override
  void initState() {
    super.initState();
    final id = widget.preselectedId;
    if (id != null) _picked.add(id);
  }

  Future<void> _confirm(int count) async {
    final l10n = AppLocalizations.of(context)!;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navyMid,
        title: Text(l10n.packPickConfirmTitle, style: AppTextStyles.headlineSmall),
        content: Text(l10n.packPickConfirmBody, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm, style: const TextStyle(color: AppColors.goldAccent)),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final controller = ref.read(scenarioUnlockControllerProvider.notifier);
    // Keep the list's order, so the account holds them as shown.
    final choices = ref.read(packChoicesProvider);
    final ids = [
      for (final c in choices)
        if (_picked.contains(c.scenario.scenarioId)) c.scenario.scenarioId,
    ];
    final saved = await controller.choosePackScenarios(ids);
    if (!mounted) return;
    if (saved) {
      ErrorSnackbar.showSuccess(context, l10n.packPickDone(count));
      Navigator.pop(context, true);
    } else if (ref.read(scenarioUnlockControllerProvider).error == 'err_pack_already_chosen') {
      // Chosen before (another phone): the account's choice now shows.
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final choices = ref.watch(packChoicesProvider);
    final worldviews = ref.watch(gameConfigProvider).worldviews;
    final unlockState = ref.watch(scenarioUnlockControllerProvider);
    final count = packChoiceCount(choices.length);
    // A preselected scenario that isn't a choice (unlocked meanwhile) is dropped.
    _picked.removeWhere((id) => !choices.any((c) => c.scenario.scenarioId == id));
    final full = _picked.length >= count;

    final rows = <Widget>[];
    String? world;
    for (final choice in choices) {
      final s = choice.scenario;
      if (s.worldviewKey != world) {
        world = s.worldviewKey;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
          child: Text(
            worldviews[world]?.localizedTitle(lang) ?? world,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.goldAccent,
              letterSpacing: 1.5,
            ),
          ),
        ));
      }
      final picked = _picked.contains(s.scenarioId);
      rows.add(_ChoiceRow(
        scenario: s,
        lang: lang,
        picked: picked,
        unlockedHere: choice.unlockedHere,
        onTap: unlockState.isUnlocking || (!picked && full)
            ? null
            : () => setState(() => picked ? _picked.remove(s.scenarioId) : _picked.add(s.scenarioId)),
      ));
    }

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(l10n.packPickTitle, style: AppTextStyles.headlineLarge),
              const SizedBox(height: 8),
              if (choices.isEmpty)
                Expanded(child: Text(l10n.packPickNothing, style: AppTextStyles.bodyMedium))
              else ...[
                Text(l10n.packPickBody(count), style: AppTextStyles.bodySmall),
                const SizedBox(height: 12),
                Text(
                  l10n.packPickCount(_picked.length, count),
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.goldAccent),
                ),
                Expanded(child: ListView(children: rows)),
                if (unlockState.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    localizedError(unlockState.error!, l10n),
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.warRedBright),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _picked.length == count && !unlockState.isUnlocking
                      ? () => _confirm(count)
                      : null,
                  child: unlockState.isUnlocking
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.packPickConfirm(count)),
                ),
              ],
              TextButton(
                onPressed: unlockState.isUnlocking ? null : () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final ScenarioModel scenario;
  final String lang;
  final bool picked;
  final bool unlockedHere;

  /// Null when the row can't be changed (the choice is full, or saving).
  final VoidCallback? onTap;

  const _ChoiceRow({
    required this.scenario,
    required this.lang,
    required this.picked,
    required this.unlockedHere,
    required this.onTap,
  });

  String _battleType(AppLocalizations l10n) {
    switch (scenario.battleType) {
      case BattleType.boss:
        return l10n.battleTypeBoss;
      case BattleType.history:
        return l10n.battleTypeHistory;
      case BattleType.standard:
        return l10n.battleTypeStandard;
    }
  }

  String _difficulty(AppLocalizations l10n) {
    switch (scenario.difficulty) {
      case 1: return l10n.difficultyNovice;
      case 2: return l10n.difficultySoldier;
      case 3: return l10n.difficultyCaptain;
      case 4: return l10n.difficultyGeneral;
      case 5: return l10n.difficultyWarlord;
      default: return l10n.difficultyUnknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = picked ? AppColors.goldAccent : AppColors.borderColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: onTap == null && !picked ? 0.5 : 1.0,
        child: Material(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color, width: picked ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Icon(
                    picked ? Icons.check_box : Icons.check_box_outline_blank,
                    color: picked ? AppColors.goldAccent : AppColors.textMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scenario.localizedTitle(lang), style: AppTextStyles.labelLarge),
                        const SizedBox(height: 2),
                        Text(
                          '${_battleType(l10n)} · ${_difficulty(l10n)}',
                          style: AppTextStyles.bodySmall,
                        ),
                        if (unlockedHere)
                          Text(
                            l10n.packPickPhoneOnly,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
