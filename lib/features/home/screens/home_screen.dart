import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../features/game_mode_selection/game_mode_providers.dart';
import '../../../features/settings/settings_providers.dart';
import '../home_providers.dart';
import '../widgets/ad_ticket_button.dart';
import '../../../services/sound/sound_service_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(soundServiceProvider).playBgm('bgm_home.mp3');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(currentUserModelProvider);
    final dailyRewardAsync = ref.watch(dailyRewardAvailableProvider);
    final homeState = ref.watch(homeControllerProvider);
    final authState = ref.watch(authStateChangesProvider);
    final user = authState.valueOrNull;

    final ticketCount = userAsync.maybeWhen(
      data: (u) => u?.ticketCount ?? 0,
      orElse: () => 0,
    );
    final isDailyAvailable = dailyRewardAsync.maybeWhen(
      data: (v) => v,
      orElse: () => false,
    );
    final displayName = userAsync.maybeWhen(
      data: (u) => u?.displayName ?? l10n.anonymousCommander,
      orElse: () => l10n.anonymousCommander,
    );
    final losses = userAsync.maybeWhen(
      data: (u) => u?.totalLosses ?? 0,
      orElse: () => 0,
    );
    final wins = userAsync.maybeWhen(
      data: (u) => u?.totalWins ?? 0,
      orElse: () => 0,
    );
    final isAnonymous = user?.isAnonymous ?? false;
    final hasRace = ref.watch(hasRaceProvider);
    final worldviews = ref.watch(availableWorldviewsProvider);
    final selectedWorldviewKey = ref.watch(selectedWorldviewKeyProvider);
    final locale = ref.watch(localeProvider).languageCode;
    final selectedWorldTitle = worldviews.isNotEmpty
        ? (worldviews[selectedWorldviewKey]?.localizedTitle(locale) ??
            worldviews.values.first.localizedTitle(locale))
        : '';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: AppColors.deepNavy,
            pinned: true,
            elevation: 0,
            title: Row(
              children: [
                // Avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.orange.withValues(alpha: 0.8),
                        AppColors.purple,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.homeHello(displayName),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textWhite,
                          fontSize: 15,
                        ),
                      ),
                      if (isAnonymous)
                        Text(
                          l10n.homeGuestAccount,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.amber.shade400,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Notification bell
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {},
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats card
                _StatsCard(losses: losses, wins: wins, tickets: ticketCount),
                const SizedBox(height: 16),

                // World Setting quick-switch banner
                const _WorldSettingBanner(),
                const SizedBox(height: 16),

                // No-race banner
                if (!hasRace) ...[
                  GestureDetector(
                    onTap: () => context.push(
                      RouteNames.raceCreation,
                      extra: {'redirectToBattle': true},
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.orange.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: AppColors.orange,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.homeNoRaceBanner,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.orange,
                                  ),
                                ),
                                Text(
                                  l10n.homeNoRaceBannerSub,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.orange.withValues(
                                      alpha: 0.75,
                                    ),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.orange.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Hero Play Button
                GestureDetector(
                  onTap: () {
                    if (!hasRace) {
                      context.push(
                        RouteNames.raceCreation,
                        extra: {'redirectToBattle': true},
                      );
                    } else {
                      context.push(RouteNames.worldSetting);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF3D0A00),
                          Color(0xFF7A1800),
                          Color(0xFFB83200),
                        ],
                        stops: [0.0, 0.5, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.goldDim.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB83200).withValues(alpha: 0.5),
                          blurRadius: 28,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Gold divider line at top
                        Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.goldAccent.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.military_tech,
                                color: AppColors.goldLight,
                                size: 30,
                              ),
                              const SizedBox(width: 14),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.homePlay,
                                    style: AppTextStyles.headlineMedium.copyWith(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                  if (selectedWorldTitle.isNotEmpty)
                                    Text(
                                      selectedWorldTitle,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.goldDim,
                                        fontSize: 11,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              const Icon(
                                Icons.military_tech,
                                color: AppColors.goldLight,
                                size: 30,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                Text(l10n.homeQuickActions, style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                _QuickActionButton(
                  label: l10n.homeDailyMissions,
                  icon: Icons.assignment_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  ),
                  trailing: isDailyAvailable
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.victoryGreen.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.victoryGreen),
                          ),
                          child: Text(
                            l10n.homeReady,
                            style: TextStyle(
                              color: AppColors.victoryGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: () async {
                    if (!isDailyAvailable) {
                      ErrorSnackbar.showError(
                        context,
                        l10n.homeDailyAlreadyClaimed,
                      );
                      return;
                    }
                    final controller = ref.read(
                      homeControllerProvider.notifier,
                    );
                    final success = await controller.claimDailyReward();
                    if (success && context.mounted) {
                      ErrorSnackbar.showSuccess(context, l10n.homeDailySuccess);
                      ref.invalidate(currentUserModelProvider);
                      ref.invalidate(dailyRewardAvailableProvider);
                    }
                  },
                ),
                const SizedBox(height: 10),
                _QuickActionButton(
                  label: l10n.homeLeaderboard,
                  icon: Icons.leaderboard_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9D68F5)],
                  ),
                  onTap: () => context.go(RouteNames.pvpLobby),
                ),
                const SizedBox(height: 24),

                // Recommended section
                Text(l10n.homeRecommended, style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                _RecommendedTile(
                  icon: Icons.smart_toy_outlined,
                  iconColor: AppColors.blue,
                  title: l10n.homeChallengeAI,
                  subtitle: l10n.homeChallengeAISubtitle,
                  onTap: () {
                    if (!hasRace) {
                      context.push(
                        RouteNames.raceCreation,
                        extra: {'redirectToBattle': true},
                      );
                    } else {
                      context.push(RouteNames.worldSetting);
                    }
                  },
                ),
                const SizedBox(height: 8),
                _RecommendedTile(
                  icon: Icons.people_outlined,
                  iconColor: AppColors.teal,
                  title: l10n.homeMultiplayer,
                  subtitle: l10n.homeMultiplayerSubtitle,
                  onTap: () => context.go(RouteNames.pvpLobby),
                ),
                const SizedBox(height: 8),
                _RecommendedTile(
                  icon: Icons.history_edu_outlined,
                  iconColor: AppColors.purple,
                  title: l10n.homeWarHistory,
                  subtitle: l10n.homeWarHistorySubtitle,
                  onTap: () => context.push(RouteNames.warHistory),
                ),
                const SizedBox(height: 24),

                // Ad ticket button
                AdTicketButton(
                  isLoading: homeState.isWatchingAd,
                  onWatch: () async {
                    final controller = ref.read(
                      homeControllerProvider.notifier,
                    );
                    final success = await controller.watchAdForTickets();
                    if (success && context.mounted) {
                      ErrorSnackbar.showSuccess(context, l10n.homeAdReward);
                      ref.invalidate(currentUserModelProvider);
                    } else if (context.mounted && !success) {
                      ErrorSnackbar.showError(context, l10n.homeAdNotAvailable);
                    }
                  },
                ),

                if (isAnonymous) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.push(RouteNames.accountLink),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            color: Colors.amber.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.homeLinkAccountBanner,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.amber.shade300,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.amber.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldSettingBanner extends ConsumerWidget {
  const _WorldSettingBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final worldviews = ref.watch(availableWorldviewsProvider);
    final selectedKey = ref.watch(selectedWorldviewKeyProvider);
    final locale = ref.watch(localeProvider).languageCode;

    if (worldviews.isEmpty) {
      return Text(
        l10n.homeWorldSettingNone,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.homeWorldSetting.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push(RouteNames.worldSetting),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.goldDim.withValues(alpha: 0.6), width: 1.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.homeWorldSettingChange,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.goldDim,
                    letterSpacing: 1.0,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: worldviews.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final entry = worldviews.entries.elementAt(index);
              final isSelected =
                  entry.key == selectedKey || (selectedKey.isEmpty && index == 0);
              return GestureDetector(
                onTap: () =>
                    ref.read(selectedWorldviewKeyProvider.notifier).state =
                        entry.key,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.goldAccent.withValues(alpha: 0.15)
                        : AppColors.navyMid,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.goldAccent
                          : AppColors.borderSubtle,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.public,
                        size: 13,
                        color: isSelected
                            ? AppColors.goldAccent
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.value.localizedTitle(locale),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.goldAccent
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int losses;
  final int wins;
  final int tickets;

  const _StatsCard({
    required this.losses,
    required this.wins,
    required this.tickets,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E1C2A), Color(0xFF162436), Color(0xFF0A1620)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gold metallic top stripe
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.goldDim.withValues(alpha: 0.4),
                  AppColors.goldAccent,
                  AppColors.goldDim.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Trophy icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: AppColors.goldAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Stats
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: l10n.homeLosses,
                        value: losses.toString(),
                        color: AppColors.defeatRed,
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: AppColors.borderSubtle,
                      ),
                      _StatItem(
                        label: l10n.homeWins,
                        value: wins.toString(),
                        color: AppColors.victoryGreen,
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: AppColors.borderSubtle,
                      ),
                      _StatItem(
                        label: l10n.tickets,
                        value: tickets.toString(),
                        color: AppColors.goldAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(
            color: color,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Widget? trailing;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
            const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _RecommendedTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RecommendedTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelLarge),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
