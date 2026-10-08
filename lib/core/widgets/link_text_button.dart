import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/legal_links.dart';
import 'error_snackbar.dart';

/// A small underlined link that opens [url] outside the app.
class LinkTextButton extends StatelessWidget {
  const LinkTextButton({super.key, required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        final opened = await LegalLinks.open(url);
        if (!opened && context.mounted) {
          ErrorSnackbar.showError(context, AppLocalizations.of(context)!.linkOpenFailed);
        }
      },
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.goldAccent,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.goldAccent,
        ),
      ),
    );
  }
}
