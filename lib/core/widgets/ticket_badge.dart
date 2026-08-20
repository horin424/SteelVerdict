import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class TicketBadge extends StatelessWidget {
  final int ticketCount;
  final bool isCompact;

  const TicketBadge({
    super.key,
    required this.ticketCount,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.navyMid,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.goldAccent,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldAccent.withValues(alpha: 0.15),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.confirmation_number,
            color: AppColors.goldLight,
            size: isCompact ? 14 : 18,
          ),
          const SizedBox(width: 4),
          Text(
            ticketCount.toString(),
            style: isCompact
                ? AppTextStyles.labelSmall.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.bold,
                  )
                : AppTextStyles.ticketCount,
          ),
        ],
      ),
    );
  }
}
