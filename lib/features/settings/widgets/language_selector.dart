import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class LanguageSelector extends StatelessWidget {
  final String currentLanguageCode;
  final ValueChanged<String> onChanged;

  const LanguageSelector({
    super.key,
    required this.currentLanguageCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyMid,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.settingsLanguage, style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LangOption(
                  code: 'en',
                  label: AppLocalizations.of(context)!.settingsLangEnglish,
                  flag: '🇺🇸',
                  isSelected: currentLanguageCode == 'en',
                  onTap: () => onChanged('en'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LangOption(
                  code: 'ja',
                  label: AppLocalizations.of(context)!.settingsLangJapanese,
                  flag: '🇯🇵',
                  isSelected: currentLanguageCode == 'ja',
                  onTap: () => onChanged('ja'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String code;
  final String label;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangOption({
    required this.code,
    required this.label,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
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
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
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
