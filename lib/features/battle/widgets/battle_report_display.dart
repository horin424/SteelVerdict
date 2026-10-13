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

  static final _rule = RegExp(r'^\s*([-*_])\1{2,}\s*$');
  static final _heading = RegExp(r'^(#{1,6})\s+(.*)$');

  /// **bold** and *italic* inside a line. The models use them mid-sentence,
  /// and they showed as literal asterisks (B22). An unmatched * stays as is.
  static final _inline = RegExp(r'\*\*(.+?)\*\*|\*(?![\s*])(.+?)(?<![\s*])\*');

  static TextSpan inlineSpans(String text, TextStyle style) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _inline.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(m.group(1) != null
          ? TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.bold))
          : TextSpan(text: m.group(2), style: const TextStyle(fontStyle: FontStyle.italic)));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return TextSpan(style: style, children: spans);
  }

  Widget _renderLine(String line) {
    final heading = _heading.firstMatch(line);
    if (_rule.hasMatch(line)) {
      // ---, *** or ___: a rule. "***" used to crash the bold-line case below.
      return Divider(
        height: 24,
        color: isParchmentStyle ? AppColors.borderColor : AppColors.borderGold,
      );
    } else if (line.length > 4 && line.startsWith('**') && line.endsWith('**')) {
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
    } else if (heading != null && heading.group(1)!.length >= 2) {
      // ## and smaller. ### and below showed their marks before.
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text.rich(inlineSpans(
          heading.group(2)!,
          isParchmentStyle
              ? AppTextStyles.headlineSmall.copyWith(color: AppColors.inkBrown)
              : AppTextStyles.headlineSmall,
        )),
      );
    } else if (heading != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text.rich(inlineSpans(
          heading.group(2)!,
          isParchmentStyle
              ? AppTextStyles.headlineMedium.copyWith(color: AppColors.inkBrown)
              : AppTextStyles.headlineMedium,
        )),
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
              child: Text.rich(inlineSpans(
                line.substring(2),
                isParchmentStyle
                    ? AppTextStyles.battleReport
                    : AppTextStyles.bodyMedium,
              )),
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
        child: Text.rich(inlineSpans(
          line,
          isParchmentStyle
              ? AppTextStyles.battleReport
              : AppTextStyles.bodyMedium,
        )),
      );
    }
  }
}
