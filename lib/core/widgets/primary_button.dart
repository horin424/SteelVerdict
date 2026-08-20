import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final int? ticketCost;
  final IconData? icon;
  final bool isDestructive;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.ticketCost,
    this.icon,
    this.isDestructive = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDestructive ? AppColors.warRed : AppColors.goldAccent;
    final effectiveForeground = isDestructive ? AppColors.parchmentLight : AppColors.inkBrown;

    Widget buttonChild;
    if (isLoading) {
      buttonChild = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(effectiveForeground),
        ),
      );
    } else {
      final children = <Widget>[];
      if (icon != null) {
        children.add(Icon(icon, size: 18, color: effectiveForeground));
        children.add(const SizedBox(width: 8));
      }
      children.add(Text(label, style: AppTextStyles.labelLarge.copyWith(color: effectiveForeground)));
      if (ticketCost != null) {
        children.add(const SizedBox(width: 8));
        children.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: effectiveForeground.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.confirmation_number, size: 12, color: effectiveForeground),
                const SizedBox(width: 2),
                Text(
                  '$ticketCost',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: effectiveForeground,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveColor,
        foregroundColor: effectiveForeground,
        disabledBackgroundColor: AppColors.textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      child: buttonChild,
    );

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}
