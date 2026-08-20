import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/battle_api/battle_api_service.dart';

class ModelSelectorRow extends StatelessWidget {
  final ModelChoice selectedModel;
  final ValueChanged<ModelChoice> onChanged;

  const ModelSelectorRow({
    super.key,
    required this.selectedModel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.navyMid,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.gameModeAiModel, style: AppTextStyles.labelLarge),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.gameModeAiModelDesc,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModelOption(
                  label: 'Gemini',
                  icon: Icons.auto_awesome,
                  isSelected: selectedModel == ModelChoice.gemini,
                  onTap: () => onChanged(ModelChoice.gemini),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModelOption(
                  label: 'Claude',
                  icon: Icons.psychology,
                  isSelected: selectedModel == ModelChoice.claude,
                  onTap: () => onChanged(ModelChoice.claude),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModelOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModelOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.goldAccent.withValues(alpha: 0.15)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.goldAccent : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
