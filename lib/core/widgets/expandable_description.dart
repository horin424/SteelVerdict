import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../l10n/app_localizations.dart';

/// Shows short descriptions compactly; long ones get Read more / もっと見る.
class ExpandableDescription extends StatefulWidget {
  final String text;
  final int collapsedMaxLines;
  final TextStyle? style;

  const ExpandableDescription({
    super.key,
    required this.text,
    this.collapsedMaxLines = 3,
    this.style,
  });

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _expanded = false;
  bool _needsToggle = false;

  @override
  void didUpdateWidget(covariant ExpandableDescription oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _expanded = false;
      _needsToggle = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = widget.style ??
        AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
        );

    if (widget.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.collapsedMaxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final overflows = painter.didExceedMaxLines;
        if (overflows != _needsToggle) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _needsToggle = overflows);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : widget.collapsedMaxLines,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (_needsToggle || _expanded)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _expanded ? l10n.showLess : l10n.readMore,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.goldAccent,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
