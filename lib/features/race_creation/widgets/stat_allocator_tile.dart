import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class StatAllocatorTile extends StatelessWidget {
  final String statKey;
  final String statLabel;
  final String? description;
  final int value;
  final int maxValue;
  final bool canIncrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const StatAllocatorTile({
    super.key,
    required this.statKey,
    required this.statLabel,
    required this.value,
    required this.maxValue,
    required this.canIncrement,
    required this.onIncrement,
    required this.onDecrement,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value > 0 ? AppColors.goldAccent.withValues(alpha: 0.4) : AppColors.borderColor,
        ),
      ),
      child: Row(
        children: [
          // Label + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      statLabel.toUpperCase(),
                      style: AppTextStyles.labelLarge,
                    ),
                    if (description != null) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: description!,
                        child: const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                if (description != null)
                  Text(
                    description!,
                    style: AppTextStyles.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Controls
          Row(
            children: [
              _ControlButton(
                icon: Icons.remove,
                onPressed: value > 0 ? onDecrement : null,
              ),
              SizedBox(
                width: 40,
                child: Text(
                  value.toString(),
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: value > 0 ? AppColors.goldAccent : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              _ControlButton(
                icon: Icons.add,
                onPressed: canIncrement ? onIncrement : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _ControlButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: onPressed != null ? AppColors.goldAccent : AppColors.textMuted,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: onPressed != null ? AppColors.goldAccent : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
