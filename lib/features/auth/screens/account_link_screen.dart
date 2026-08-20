import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/l10n/app_localizations.dart';
import '../auth_providers.dart';
import '../widgets/anonymous_warning_banner.dart';

String _localizeAuthError(String code, AppLocalizations l10n) {
  switch (code) {
    case 'auth_err_no_account': return l10n.authErrNoAccount;
    case 'auth_err_wrong_password': return l10n.authErrWrongPassword;
    case 'auth_err_email_in_use': return l10n.authErrEmailInUse;
    case 'auth_err_weak_password': return l10n.authErrWeakPassword;
    case 'auth_err_invalid_email': return l10n.authErrInvalidEmail;
    case 'auth_err_credential_in_use': return l10n.authErrCredentialInUse;
    case 'auth_err_sign_in_failed': return l10n.authErrSignInFailed;
    case 'auth_err_sign_out_failed': return l10n.authErrSignOutFailed;
    default: return l10n.authErrDefault;
  }
}

class AccountLinkScreen extends ConsumerWidget {
  const AccountLinkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(l10n.authLinkTitle, style: AppTextStyles.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AnonymousWarningBanner(),
            const SizedBox(height: 24),
            Text(
              l10n.authLinkTitle,
              style: AppTextStyles.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.authLinkSubtitle,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      labelText: l10n.authEmail,
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.authEmailRequired;
                      if (!v.contains('@')) return l10n.authEmailInvalid;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      labelText: l10n.authPassword,
                      prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.textMuted),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.authPasswordRequired;
                      if (v.length < 6) return l10n.authPasswordMinLength;
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final controller =
                                  ref.read(authControllerProvider.notifier);
                              final success = await controller.linkWithEmail(
                                emailController.text.trim(),
                                passwordController.text,
                              );
                              if (success && context.mounted) {
                                ErrorSnackbar.showSuccess(
                                  context,
                                  l10n.authLinkSuccess,
                                );
                                context.pop();
                              } else if (context.mounted) {
                                final state = ref.read(authControllerProvider);
                                if (state.errorMessage != null) {
                                  final l10n = AppLocalizations.of(context)!;
                                  ErrorSnackbar.showError(
                                    context,
                                    _localizeAuthError(state.errorMessage!, l10n),
                                  );
                                }
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: authState.isLoading
                        ? const CircularProgressIndicator()
                        : Text(l10n.authLinkTitle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
