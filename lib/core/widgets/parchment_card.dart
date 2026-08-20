import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ParchmentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool hasBorder;
  final bool isGoldBorder;
  final VoidCallback? onTap;
  final double borderRadius;

  const ParchmentCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.hasBorder = true,
    this.isGoldBorder = false,
    this.onTap,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isGoldBorder ? AppColors.borderGold : AppColors.borderColor;

    final decoration = BoxDecoration(
      color: AppColors.parchmentLight,
      borderRadius: BorderRadius.circular(borderRadius),
      border: hasBorder ? Border.all(color: borderColor, width: 1.5) : null,
      boxShadow: [
        BoxShadow(
          color: AppColors.darkBackground.withValues(alpha: 0.4),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        if (isGoldBorder)
          BoxShadow(
            color: AppColors.goldAccent.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 0,
          ),
      ],
    );

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }
}

/// A dark-themed card with optional gold border for the military UI.
class MilitaryCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isGoldBorder;
  final VoidCallback? onTap;
  final double borderRadius;

  const MilitaryCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.isGoldBorder = false,
    this.onTap,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isGoldBorder ? AppColors.borderGold : AppColors.borderColor;

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBackground.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.goldAccent.withValues(alpha: 0.1),
          highlightColor: AppColors.goldAccent.withValues(alpha: 0.05),
          child: content,
        ),
      );
    }

    return content;
  }
}
