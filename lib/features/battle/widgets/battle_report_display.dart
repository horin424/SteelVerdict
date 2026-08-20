import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class BattleReportDisplay extends StatelessWidget {
  final String reportText;
  final bool isParchmentStyle;

  const BattleReportDisplay({
    super.key,
    required this.reportText,
    this.isParchmentStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isParchmentStyle ? AppColors.parchmentLight : AppColors.navyMid,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isParchmentStyle ? AppColors.borderColor : AppColors.borderGold,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBackground.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: _buildReportContent(reportText),
    );
  }

  Widget _buildReportContent(String text) {
    // Split by lines and render with basic markdown support
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) => _renderLine(line)).toList(),
    );
  }

  Widget _renderLine(String line) {
    if (line.startsWith('**') && line.endsWith('**')) {
      final content = line.substring(2, line.length - 2);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          content,
          style: isParchmentStyle
              ? AppTextStyles.headlineSmall.copyWith(color: AppColors.inkBrown)
              : AppTextStyles.headlineSmall,
        ),
      );
    } else if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          line.substring(3),
          style: isParchmentStyle
              ? AppTextStyles.headlineSmall.copyWith(color: AppColors.inkBrown)
              : AppTextStyles.headlineSmall,
        ),
      );
    } else if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(
          line.substring(2),
          style: isParchmentStyle
              ? AppTextStyles.headlineMedium.copyWith(color: AppColors.inkBrown)
              : AppTextStyles.headlineMedium,
        ),
      );
    } else if (line.startsWith('- ') || line.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ',
              style: isParchmentStyle
                  ? AppTextStyles.battleReport
                  : AppTextStyles.bodyMedium,
            ),
            Expanded(
              child: Text(
                line.substring(2),
                style: isParchmentStyle
                    ? AppTextStyles.battleReport
                    : AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ),
      );
    } else if (line.startsWith('*') && line.endsWith('*') && !line.startsWith('**')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          line.substring(1, line.length - 1),
          style: isParchmentStyle
              ? AppTextStyles.battleReport.copyWith(fontStyle: FontStyle.italic)
              : AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    } else if (line.trim().isEmpty) {
      return const SizedBox(height: 8);
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          line,
          style: isParchmentStyle
              ? AppTextStyles.battleReport
              : AppTextStyles.bodyMedium,
        ),
      );
    }
  }
}
