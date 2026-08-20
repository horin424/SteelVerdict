import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/scenario_model.dart';
import '../../../core/l10n/app_localizations.dart';
import '../scenario_providers.dart';

class UnlockDialog extends ConsumerWidget {
  final ScenarioModel scenario;
  final VoidCallback onUnlocked;

  const UnlockDialog({
    super.key,
    required this.scenario,
    required this.onUnlocked,
  });

  static Future<void> show(
    BuildContext context, {
    required ScenarioModel scenario,
    required VoidCallback onUnlocked,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.borderGold),
      ),
      builder: (ctx) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: UnlockDialog(scenario: scenario, onUnlocked: onUnlocked),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final unlockState = ref.watch(scenarioUnlockControllerProvider);
    final controller = ref.read(scenarioUnlockControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.lock_open, color: AppColors.goldAccent, size: 40),
          const SizedBox(height: 16),
          Text(
            l10n.unlockScenarioTitle,
            style: AppTextStyles.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            scenario.title,
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.goldAccent),
          ),
          const SizedBox(height: 24),

          // Watch Ad option
          _UnlockOption(
            icon: Icons.play_circle_outline,
            title: l10n.unlockWatchAd,
            subtitle: l10n.unlockWatchAdDesc,
            badge: l10n.unlockFree,
            badgeColor: AppColors.victoryGreen,
            isLoading: unlockState.isUnlocking,
            onTap: () async {
              final success = await controller.unlockWithAd(scenario.scenarioId);
              if (success && context.mounted) {
                Navigator.pop(context);
                onUnlocked();
              }
            },
          ),
          const SizedBox(height: 12),

          // Purchase option
          _UnlockOption(
            icon: Icons.shopping_cart_outlined,
            title: l10n.unlockPurchase,
            subtitle: l10n.unlockPurchaseDesc,
            badge: '¥120',
            badgeColor: AppColors.goldAccent,
            isLoading: unlockState.isUnlocking,
            onTap: () async {
              final success = await controller.unlockWithPurchase(scenario.scenarioId);
              if (success && context.mounted) {
                Navigator.pop(context);
                onUnlocked();
              }
            },
          ),

          if (unlockState.error != null) ...[
            const SizedBox(height: 12),
            Text(
              unlockState.error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.warRedBright),
            ),
          ],
          const SizedBox(height: 16),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

class _UnlockOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final bool isLoading;
  final VoidCallback onTap;

  const _UnlockOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: badgeColor, size: 28),
              const SizedBox(width: 12),
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
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  badge,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
