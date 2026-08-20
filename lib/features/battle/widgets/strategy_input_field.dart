import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';

class StrategyInputField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool enabled;

  const StrategyInputField({
    super.key,
    required this.controller,
    this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<StrategyInputField> createState() => _StrategyInputFieldState();
}

class _StrategyInputFieldState extends State<StrategyInputField> {
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _charCount = widget.controller.text.length;
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    setState(() => _charCount = widget.controller.text.length);
    widget.onChanged?.call(widget.controller.text);
  }

  Color _countColor() {
    if (_charCount > AppConstants.maxStrategyLength) return AppColors.warRedBright;
    if (_charCount > AppConstants.maxStrategyLength * 0.8) return AppColors.goldAccent;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.battleStrategyLabel, style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.navyMid,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.errorText != null ? AppColors.warRedBright : AppColors.borderColor,
              width: widget.errorText != null ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            enabled: widget.enabled,
            maxLines: 10,
            minLines: 6,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.battleStrategyHintFull,
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.errorText != null)
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.warRedBright),
                ),
              ),
            Spacer(),
            Text(
              '$_charCount / ${AppConstants.maxStrategyLength}',
              style: AppTextStyles.labelSmall.copyWith(color: _countColor()),
            ),
          ],
        ),
        if (_charCount < AppConstants.minStrategyLength && _charCount > 0)
          Text(
            AppLocalizations.of(context)!.battleNeedMoreChars(AppConstants.minStrategyLength - _charCount),
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.goldAccent),
          ),
      ],
    );
  }
}
