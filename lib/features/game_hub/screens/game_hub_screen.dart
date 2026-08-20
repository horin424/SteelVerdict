import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/ticket_badge.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../models/race_model.dart';

class GameHubScreen extends ConsumerWidget {
  const GameHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(currentUserModelProvider);
    final ticketCount = userAsync.maybeWhen(
      data: (u) => u?.ticketCount ?? 0,
      orElse: () => 0,
    );
    final race = ref.watch(currentRaceProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(l10n.gameHubTitle, style: AppTextStyles.headlineMedium),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TicketBadge(ticketCount: ticketCount),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Choose Game Mode header
            Text(l10n.gameHubChooseMode, style: AppTextStyles.headlineLarge),
            const SizedBox(height: 4),
            Text(
              l10n.gameHubSelectHow,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),

            // Single Player card
            _GameModeCard(
              title: l10n.gameHubSinglePlayer,
              subtitle: l10n.gameHubPlayVsAI,
              description: l10n.gameHubSinglePlayerDesc,
              icon: Icons.person,
              gradient: const LinearGradient(
                colors: [Color(0xFF091828), Color(0xFF0E2A4A), Color(0xFF1A4A8A)],
                stops: [0.0, 0.4, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              badgeLabel: l10n.gameHubVsAI,
              badgeColor: AppColors.blue,
              onTap: () => context.push(RouteNames.battleType),
            ),
            const SizedBox(height: 16),

            // Multiplayer card
            _GameModeCard(
              title: l10n.gameHubMultiplayer,
              subtitle: l10n.gameHubPlayOnline,
              description: l10n.gameHubMultiplayerDesc,
              icon: Icons.people,
              gradient: const LinearGradient(
                colors: [Color(0xFF061A18), Color(0xFF0A2E2A), Color(0xFF0A706A)],
                stops: [0.0, 0.4, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              badgeLabel: l10n.gameHubLive,
              badgeColor: AppColors.teal,
              onTap: () => context.go(RouteNames.pvpLobby),
            ),
            const SizedBox(height: 28),

            // Management section
            Text(l10n.gameHubManagement, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            _ProgressTile(
              icon: Icons.shield_outlined,
              iconColor: AppColors.goldAccent,
              title: l10n.gameHubMyRace,
              subtitle: l10n.gameHubMyRaceDesc,
              trailing: race != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.goldAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        race.raceName,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.goldAccent,
                          fontSize: 11,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
              onTap: () => _showMyRaceSheet(context, race, l10n),
            ),
            const SizedBox(height: 8),
            _ProgressTile(
              icon: Icons.history_edu_outlined,
              iconColor: AppColors.purple,
              title: l10n.warHistoryTitle,
              subtitle: l10n.gameHubWarHistoryDesc,
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textMuted,
              ),
              onTap: () => context.push(RouteNames.warHistory),
            ),
            const SizedBox(height: 8),
            _ProgressTile(
              icon: Icons.confirmation_number_outlined,
              iconColor: AppColors.orange,
              title: l10n.shopTitle,
              subtitle: l10n.gameHubShopDesc,
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textMuted,
              ),
              onTap: () => context.push(RouteNames.shop),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showMyRaceSheet(
    BuildContext context,
    RaceModel? race,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _MyRaceSheet(race: race, l10n: l10n),
    );
  }
}

class _MyRaceSheet extends StatelessWidget {
  final RaceModel? race;
  final AppLocalizations l10n;

  const _MyRaceSheet({required this.race, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
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

          if (race == null) ...[
            Center(
              child: Column(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(l10n.myRaceNoRace,
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ] else ...[
            // ignore: null safety narrowed via null check above
            Builder(builder: (context) {
              final r = race!;
              return _RaceDetail(race: r, l10n: l10n);
            }),
          ],
        ],
      ),
    );
  }
}

class _RaceDetail extends StatelessWidget {
  final RaceModel race;
  final AppLocalizations l10n;

  const _RaceDetail({required this.race, required this.l10n});

  String _statLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'strength': return l10n.statStrength;
      case 'intellect': return l10n.statIntellect;
      case 'skill': return l10n.statSkill;
      case 'magic': return l10n.statMagic;
      case 'art': return l10n.statArt;
      case 'life': return l10n.statLife;
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
            // Race name + header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield,
                      color: AppColors.goldAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(race.raceName,
                          style: AppTextStyles.headlineMedium),
                      if (race.overview.isNotEmpty)
                        Text(
                          race.overview,
                          style: AppTextStyles.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats
            Text(l10n.myRaceStats,
                style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: race.stats.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${_statLabel(e.key, l10n)}  ',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextSpan(
                          text: '${e.value}',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        );
  }
}

class _GameModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final String badgeLabel;
  final Color badgeColor;
  final VoidCallback onTap;

  const _GameModeCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.badgeLabel,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: badgeColor.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            badgeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _ProgressTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Material(
            color: AppColors.cardSurface,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
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
                    trailing,
                  ],
                ),
              ),
            ),
          ),
          // Left metallic accent stripe
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.4),
                    iconColor,
                    iconColor.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
