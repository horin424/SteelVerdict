import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../features/auth/auth_providers.dart';
import '../pvp_providers.dart';
import '../widgets/match_card.dart';
import '../../../models/pvp_match_model.dart';

class PvpLobbyScreen extends ConsumerWidget {
  const PvpLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(activePvpMatchesProvider);
    final matchmakingState = ref.watch(pvpMatchmakingControllerProvider);
    final authState = ref.watch(authStateChangesProvider);
    final currentUid = authState.valueOrNull?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pvpLobbyTitle, style: AppTextStyles.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(activePvpMatchesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Find match button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.navyMid,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.people, color: AppColors.goldAccent, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.pvpSubtitle,
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: matchmakingState.isSearching ? AppLocalizations.of(context)!.pvpSearching : AppLocalizations.of(context)!.pvpFindMatch,
                        isLoading: matchmakingState.isSearching,
                        ticketCost: 1,
                        onPressed: matchmakingState.isSearching
                            ? null
                            : () async {
                                final controller =
                                    ref.read(pvpMatchmakingControllerProvider.notifier);
                                final match = await controller.findOrCreateMatch();
                                if (match != null && context.mounted) {
                                  ref.invalidate(activePvpMatchesProvider);
                                  ErrorSnackbar.showSuccess(
                                    context,
                                    match.status == PvpMatchStatus.waiting
                                        ? AppLocalizations.of(context)!.pvpMatchCreated
                                        : AppLocalizations.of(context)!.pvpJoined,
                                  );
                                  context.push(
                                    RouteNames.pvpBattle,
                                    extra: {'matchId': match.matchId},
                                  );
                                } else if (context.mounted) {
                                  final state = ref.read(pvpMatchmakingControllerProvider);
                                  if (state.error != null) {
                                    ErrorSnackbar.showError(context, state.error!);
                                  }
                                }
                              },
                        width: double.infinity,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Active matches
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(AppLocalizations.of(context)!.pvpActiveMatches, style: AppTextStyles.headlineSmall),
                const Spacer(),
                matchesAsync.when(
                  data: (m) => Text('${m.length}', style: AppTextStyles.bodySmall),
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: matchesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.goldAccent),
              ),
              error: (e, _) => Center(
                child: Text(AppLocalizations.of(context)!.warHistoryLoadError(e.toString()), style: AppTextStyles.bodySmall),
              ),
              data: (matches) {
                if (matches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, color: AppColors.textMuted, size: 64),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context)!.pvpNoMatches, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.pvpFindMatchHelp, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: matches.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return MatchCard(
                      match: match,
                      currentUid: currentUid,
                      onTap: () {
                        context.push(
                          RouteNames.pvpBattle,
                          extra: {'matchId': match.matchId},
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
