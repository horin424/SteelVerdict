import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ParchmentRenderWidget extends StatelessWidget {
  final GlobalKey repaintKey;
  final String title;
  final String narrative;
  final String outcome;
  final DateTime date;

  const ParchmentRenderWidget({
    super.key,
    required this.repaintKey,
    required this.title,
    required this.narrative,
    required this.outcome,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(40),
        decoration: const BoxDecoration(
          color: AppColors.parchmentLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header decoration
            Row(
              children: [
                Expanded(child: _Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Icon(Icons.shield, color: AppColors.inkBrown, size: 24),
                ),
                Expanded(child: _Divider()),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.inkBrown,
                fontFamily: 'CinzelDecorative',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Date
            Text(
              '${date.year} — A Year of Great Battles',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.inkBrownLight,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            // Outcome
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.inkBrown, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                outcome.toUpperCase(),
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.inkBrown,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Narrative
            Text(
              narrative,
              style: AppTextStyles.battleReport,
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),

            // Footer
            Row(
              children: [
                Expanded(child: _Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    AppLocalizations.of(context)!.parchmentFooter,
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.inkBrownLight),
                  ),
                ),
                Expanded(child: _Divider()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.inkBrownLight,
    );
  }
}
