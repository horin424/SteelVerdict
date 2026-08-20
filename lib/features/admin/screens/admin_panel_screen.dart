import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../services/game_config/game_config_providers.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(gameConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(l10n.adminPanel, style: AppTextStyles.headlineMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminCard(
            icon: Icons.public,
            iconColor: AppColors.blue,
            title: l10n.adminWorldviews,
            subtitle: l10n.adminWorldviewsDesc,
            count: config.worldviews.length,
            onTap: () => context.push(RouteNames.adminWorldviews),
          ),
          const SizedBox(height: 12),
          _AdminCard(
            icon: Icons.military_tech,
            iconColor: AppColors.orange,
            title: l10n.adminScenarios,
            subtitle: l10n.adminScenariosDesc,
            count: config.scenarios.length,
            onTap: () => context.push(RouteNames.adminScenarios),
          ),
          const SizedBox(height: 12),
          _AdminCard(
            icon: Icons.tune,
            iconColor: AppColors.purple,
            title: l10n.adminModeAddons,
            subtitle: l10n.adminModeAddonsDesc,
            count: config.modeAddons.length,
            onTap: () => context.push(RouteNames.adminModeAddons),
          ),
          const SizedBox(height: 12),
          _AdminCard(
            icon: Icons.confirmation_number,
            iconColor: AppColors.goldAccent,
            title: l10n.adminCosts,
            subtitle: l10n.adminCostsDesc,
            count: config.ticketCosts.length + config.modelConfig.length,
            onTap: () => context.push(RouteNames.adminCosts),
          ),
          const SizedBox(height: 12),
          _AdminCard(
            icon: Icons.settings,
            iconColor: AppColors.steelLight,
            title: 'System Config',
            subtitle: 'Fallback prompt, dev UIDs, ad units',
            count: config.devUids.length,
            onTap: () => context.push(RouteNames.adminSystemConfig),
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 26),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.navyMid,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
