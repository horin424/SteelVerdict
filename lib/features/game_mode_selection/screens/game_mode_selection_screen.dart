import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../features/settings/settings_providers.dart';
import '../../../services/battle_api/battle_api_service.dart';
import '../game_mode_providers.dart';
import '../widgets/game_mode_card.dart';

class GameModeSelectionScreen extends ConsumerWidget {
  final String scenarioId;

  const GameModeSelectionScreen({super.key, required this.scenarioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedMode = ref.watch(selectedGameModeProvider);
    final selectedModel = ref.watch(selectedModelProvider);
    final modeAvailabilityAsync = ref.watch(modeAvailabilityProvider);
    final ticketCosts = ref.watch(ticketCostsProvider);
    final effectiveCost = ref.watch(effectiveTicketCostProvider);
    final locale = ref.watch(localeProvider).languageCode;
    final selectedWorldviewKey = ref.watch(selectedWorldviewKeyProvider);
    final worldviews = ref.watch(availableWorldviewsProvider);

    final availability = modeAvailabilityAsync.maybeWhen(
      data: (v) => v,
      orElse: () => const ModeAvailability(),
    );

    final isPractice = selectedMode == 'practice';

    final modes = [
      (
        key: 'practice',
        title: l10n.gameModePractice,
        desc: l10n.gameModePracticeDesc,
        icon: Icons.school_outlined,
        available: availability.practiceAvailable,
        lockReason: null,
      ),
      (
        key: 'normal',
        title: l10n.gameModeNormal,
        desc: l10n.gameModeNormalDesc,
        icon: Icons.military_tech_outlined,
        available: availability.normalAvailable,
        lockReason: null,
      ),
      (
        key: 'tabletop',
        title: l10n.gameModeTabletop,
        desc: l10n.gameModeTabletopDesc,
        icon: Icons.grid_on_outlined,
        available: availability.tabletopAvailable,
        lockReason: null,
      ),
      (
        key: 'epic',
        title: l10n.gameModeEpic,
        desc: l10n.gameModeEpicDesc,
        icon: Icons.auto_stories_outlined,
        available: availability.epicAvailable,
        lockReason: l10n.gameModeEpicRequires,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          l10n.gameModeChooseMode,
          style: AppTextStyles.headlineMedium,
        ),
      ),
      body: Column(
        children: [
          // ── Top info bar: Model + Worldview dropdowns + Ticket cost ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.navyMid,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: AI Model dropdown + Ticket cost badge
                Row(
                  children: [
                    // AI Model dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.gameModeModelSelect,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _StyledDropdown<ModelChoice>(
                            value: isPractice
                                ? ModelChoice.gemini
                                : selectedModel,
                            items: ModelChoice.values.map((m) {
                              return DropdownMenuItem(
                                value: m,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      m == ModelChoice.gemini
                                          ? Icons.auto_awesome
                                          : Icons.psychology,
                                      size: 16,
                                      color: AppColors.goldAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      m.displayName,
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.parchmentBeige,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: isPractice
                                ? null
                                : (v) {
                                    if (v != null) {
                                      ref
                                              .read(
                                                selectedModelProvider.notifier,
                                              )
                                              .state =
                                          v;
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Ticket cost badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: effectiveCost == 0
                            ? AppColors.victoryGreen.withValues(alpha: 0.15)
                            : AppColors.goldAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: effectiveCost == 0
                              ? AppColors.victoryGreen
                              : AppColors.goldAccent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.confirmation_number,
                            size: 14,
                            color: effectiveCost == 0
                                ? AppColors.victoryGreen
                                : AppColors.goldAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            effectiveCost == 0
                                ? l10n.gameModeFree
                                : '$effectiveCost',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: effectiveCost == 0
                                  ? AppColors.victoryGreen
                                  : AppColors.goldAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Row 2: Active world badge (locked — set on World Setting screen)
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.borderSubtle),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.public,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.gameModeWorldview,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.steelDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Text(
                        worldviews.isEmpty
                            ? '--'
                            : (worldviews[selectedWorldviewKey]
                                    ?.localizedTitle(locale) ??
                                worldviews.values.first
                                    .localizedTitle(locale)),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.parchmentBeige,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Mode cards ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...modes.map(
                  (mode) {
                    final int cardCost;
                    if (mode.key == 'practice') {
                      cardCost = 0;
                    } else if (selectedModel == ModelChoice.claude) {
                      cardCost = ticketCosts['claude'] ?? 3;
                    } else {
                      cardCost = ticketCosts[mode.key] ?? 1;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GameModeCard(
                        modeKey: mode.key,
                        title: mode.title,
                        description: mode.desc,
                        icon: mode.icon,
                        ticketCost: cardCost,
                        isSelected: selectedMode == mode.key,
                        isLocked: !mode.available,
                        lockReason: mode.lockReason,
                        onTap: () {
                          ref.read(selectedGameModeProvider.notifier).state =
                              mode.key;
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Start battle button ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: PrimaryButton(
              label: l10n.gameModeStartBattle,
              ticketCost: effectiveCost,
              onPressed: () {
                context.push('${RouteNames.battle}/$scenarioId/$selectedMode');
              },
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Styled dropdown matching the dark UI ─────────────────────────────────────

class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: AppColors.navyMid,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: onChanged != null
                ? AppColors.goldAccent
                : AppColors.textMuted,
            size: 20,
          ),
          style: AppTextStyles.labelMedium,
        ),
      ),
    );
  }
}
