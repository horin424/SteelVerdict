import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../models/scenario_model.dart';
import '../../../features/game_mode_selection/game_mode_providers.dart';
import '../scenario_providers.dart';
import '../widgets/scenario_card.dart';
import '../widgets/unlock_dialog.dart';

class ScenarioSelectionScreen extends ConsumerWidget {
  final String battleType;

  const ScenarioSelectionScreen({super.key, required this.battleType});

  BattleType get _battleTypeEnum {
    switch (battleType) {
      case 'boss': return BattleType.boss;
      case 'history': return BattleType.history;
      default: return BattleType.standard;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final type = _battleTypeEnum;
    final selectedWorldviewKey = ref.watch(selectedWorldviewKeyProvider);
    final worldviewKey = selectedWorldviewKey.isNotEmpty
        ? selectedWorldviewKey
        : AppConstants.defaultWorldviewKey;
    final scenarios =
        ref.watch(scenariosByWorldviewAndTypeProvider((worldviewKey, type)));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(l10n.scenarioSelectionTitle, style: AppTextStyles.headlineMedium),
      ),
      body: scenarios.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, color: AppColors.textMuted, size: 64),
                  const SizedBox(height: 16),
                  Text(l10n.scenarioNoAvailable, style: AppTextStyles.bodyMedium),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: scenarios.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final scenario = scenarios[index];
                return ScenarioCard(
                  scenario: scenario,
                  onTap: () {
                    if (type == BattleType.boss) {
                      context.push('${RouteNames.battle}/${scenario.scenarioId}/boss');
                    } else if (type == BattleType.history) {
                      context.push('${RouteNames.battle}/${scenario.scenarioId}/history_puzzle');
                    } else {
                      context.push('${RouteNames.gameModeSelection}/${scenario.scenarioId}');
                    }
                  },
                  onUnlock: () {
                    UnlockDialog.show(
                      context,
                      scenario: scenario,
                      onUnlocked: () {
                        ref.invalidate(scenariosProvider);
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
