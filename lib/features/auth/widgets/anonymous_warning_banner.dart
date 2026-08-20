import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/l10n/app_localizations.dart';

class AnonymousWarningBanner extends StatelessWidget {
  final VoidCallback? onLinkAccount;

  const AnonymousWarningBanner({
    super.key,
    this.onLinkAccount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF664D00),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade600, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeGuestAccount,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.amber.shade200,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.authGuestProgressWarning,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.amber.shade100,
                  ),
                ),
                if (onLinkAccount != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onLinkAccount,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.authLinkAccountArrow,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
