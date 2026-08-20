import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../core/widgets/ticket_badge.dart';

class BattleTypeSelectionScreen extends ConsumerWidget {
  const BattleTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(currentUserModelProvider);
    final ticketCount = userAsync.maybeWhen(
      data: (u) => u?.ticketCount ?? 0,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(l10n.battleTypeTitle, style: AppTextStyles.headlineMedium),
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
            Text(l10n.battleTypeChoose, style: AppTextStyles.headlineLarge),
            const SizedBox(height: 4),
            Text(l10n.battleTypeSubtitle, style: AppTextStyles.bodySmall),
            const SizedBox(height: 24),

            // Standard Battle
            _BattleTypeCard(
              title: l10n.battleTypeStandard,
              description: l10n.battleTypeStandardDesc,
              icon: Icons.military_tech_outlined,
              gradient: const LinearGradient(
                colors: [Color(0xFF0A1E36), Color(0xFF1A3A6A), Color(0xFF2C5FA8)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              glowColor: Color(0xFF2C5FA8),
              badgeLabel: l10n.battleTypeSubModeBadge,
              badgeColor: AppColors.blue,
              onTap: () => context.push('${RouteNames.scenarios}/standard'),
            ),
            const SizedBox(height: 16),

            // Boss Battle
            _BattleTypeCard(
              title: l10n.battleTypeBoss,
              description: l10n.battleTypeBossDesc,
              icon: Icons.local_fire_department_outlined,
              gradient: const LinearGradient(
                colors: [Color(0xFF2A0808), Color(0xFF6B1010), Color(0xFFB81818)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              glowColor: Color(0xFFB81818),
              badgeLabel: l10n.battleTypeBossBadge,
              badgeColor: AppColors.warRedBright,
              onTap: () => context.push('${RouteNames.scenarios}/boss'),
            ),
            const SizedBox(height: 16),

            // History Puzzle
            _BattleTypeCard(
              title: l10n.battleTypeHistory,
              description: l10n.battleTypeHistoryDesc,
              icon: Icons.history_edu_outlined,
              gradient: const LinearGradient(
                colors: [Color(0xFF160A30), Color(0xFF3A1878), Color(0xFF6A30C8)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              glowColor: Color(0xFF6A30C8),
              badgeLabel: l10n.battleTypeHistoryBadge,
              badgeColor: AppColors.purple,
              onTap: () => context.push('${RouteNames.scenarios}/history'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _BattleTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;
  final String badgeLabel;
  final Color badgeColor;
  final VoidCallback onTap;

  const _BattleTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.glowColor,
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
          border: Border.all(
            color: AppColors.goldDim.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.35),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Gold top stripe
            Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.goldAccent.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
        child: Row(
          children: [
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
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
            Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.7), size: 16),
          ],
            ),
            ),
          ],
        ),
      ),
    );
  }
}
