import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';

class PvpCountdownTimer extends StatefulWidget {
  final DateTime expiresAt;
  final VoidCallback? onExpired;

  const PvpCountdownTimer({
    super.key,
    required this.expiresAt,
    this.onExpired,
  });

  @override
  State<PvpCountdownTimer> createState() => _PvpCountdownTimerState();
}

class _PvpCountdownTimerState extends State<PvpCountdownTimer> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final remaining = GameDateUtils.pvpTimeoutRemaining(widget.expiresAt);
    if (mounted) {
      setState(() => _remaining = remaining);
      if (remaining == Duration.zero) {
        _timer.cancel();
        widget.onExpired?.call();
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Color get _timerColor {
    if (_remaining.inHours >= 8) return AppColors.victoryGreen;
    if (_remaining.inHours >= 2) return AppColors.goldAccent;
    return AppColors.warRedBright;
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return Row(
        children: [
          const Icon(Icons.timer_off, color: AppColors.warRedBright, size: 16),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context)!.pvpTimerExpired,
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.warRedBright),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.timer_outlined, color: _timerColor, size: 16),
        const SizedBox(width: 6),
        Text(
          GameDateUtils.formatCountdown(_remaining),
          style: AppTextStyles.labelMedium.copyWith(
            color: _timerColor,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
