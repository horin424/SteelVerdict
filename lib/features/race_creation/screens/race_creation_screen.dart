import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/l10n/app_localizations.dart';
import '../race_creation_providers.dart';
import '../widgets/stat_allocator_tile.dart';
import '../widgets/points_remaining_indicator.dart';
import '../widgets/race_name_field.dart';

String _localizedStatName(String stat, AppLocalizations l10n) {
  switch (stat) {
    case 'strength':
      return l10n.statStrength;
    case 'intellect':
      return l10n.statIntellect;
    case 'skill':
      return l10n.statSkill;
    case 'magic':
      return l10n.statMagic;
    case 'art':
      return l10n.statArt;
    case 'life':
      return l10n.statLife;
    // legacy keys
    case 'attack':
      return l10n.statAttack;
    case 'defense':
      return l10n.statDefense;
    case 'speed':
      return l10n.statSpeed;
    case 'morale':
      return l10n.statMorale;
    case 'leadership':
      return l10n.statLeadership;
    default:
      return stat;
  }
}

class RaceCreationScreen extends ConsumerWidget {
  final bool redirectToBattle;
  const RaceCreationScreen({super.key, this.redirectToBattle = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(raceCreationControllerProvider);
    final controller = ref.read(raceCreationControllerProvider.notifier);
    final worldview = ref.watch(activeWorldviewProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          l10n.raceCreationTitle,
          style: AppTextStyles.headlineMedium,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // World info
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
                    l10n.raceCreationWorld(worldview.localizedTitle(locale)),
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    worldview.localizedDescription(locale),
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Race name field
            RaceNameField(
              initialValue: state.raceName,
              onChanged: controller.setRaceName,
            ),
            const SizedBox(height: 12),

            // Overview field
            Text(l10n.raceOverviewLabel, style: AppTextStyles.labelLarge),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppColors.navyMid,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: TextField(
                maxLines: 3,
                minLines: 2,
                maxLength: 200,
                style: AppTextStyles.bodySmall,
                onChanged: controller.setOverview,
                decoration: InputDecoration(
                  hintText: l10n.raceOverviewHint,
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                  counterStyle: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Points remaining indicator
            PointsRemainingIndicator(
              used: state.totalPoints,
              total: state.maxPoints,
            ),
            const SizedBox(height: 16),

            // Stat allocation
            Text(l10n.raceAllocateStats, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            ...worldview.stats.map((stat) {
              final description = worldview.getStatDescription(stat, locale);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: StatAllocatorTile(
                  statKey: stat,
                  statLabel: _localizedStatName(stat, l10n),
                  description: description,
                  value: state.stats[stat] ?? 0,
                  maxValue: state.isBossMode ? 999 : 10,
                  canIncrement:
                      state.remainingPoints > 0 &&
                      (state.isBossMode || (state.stats[stat] ?? 0) < 10),
                  onIncrement: () => controller.incrementStat(stat),
                  onDecrement: () => controller.decrementStat(stat),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Error message
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  state.errorMessage!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warRedBright,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Confirm button
            PrimaryButton(
              label: l10n.raceCreationConfirm,
              isLoading: state.isSaving,
              onPressed: state.isValid
                  ? () async {
                      final success = await controller.saveRace();
                      if (success && context.mounted) {
                        ErrorSnackbar.showSuccess(
                          context,
                          l10n.raceCreationSuccess,
                        );
                        if (redirectToBattle) {
                          context.go(RouteNames.worldSetting);
                        } else {
                          context.go(RouteNames.home);
                        }
                      } else if (context.mounted &&
                          state.errorMessage != null) {
                        ErrorSnackbar.showError(context, state.errorMessage!);
                      }
                    }
                  : null,
              width: double.infinity,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
