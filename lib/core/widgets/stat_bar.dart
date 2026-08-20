import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StatBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color? barColor;
  final bool showValue;

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    this.barColor,
    this.showValue = true,
  });

  Color _getBarColor() {
    if (barColor != null) return barColor!;
    final fraction = value / maxValue;
    if (fraction >= 0.7) return AppColors.victoryGreen;
    if (fraction >= 0.4) return AppColors.goldAccent;
    return AppColors.warRed;
  }

  @override
  Widget build(BuildContext context) {
    final fraction = (maxValue > 0) ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    final color = _getBarColor();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium,
              ),
              if (showValue)
                Text(
                  '$value / $maxValue',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact stat display showing just label and value without a bar.
class StatLabel extends StatelessWidget {
  final String label;
  final int value;
  final Color? valueColor;

  const StatLabel({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        Text(
          value.toString(),
          style: AppTextStyles.labelLarge.copyWith(
            color: valueColor ?? AppColors.goldAccent,
          ),
        ),
      ],
    );
  }
}
