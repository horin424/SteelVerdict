import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/l10n/app_localizations.dart';
import '../auth_providers.dart';
import '../widgets/login_form.dart';

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

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _showEmailForm = false;
  bool _isRegisterMode = false;

  Future<void> _handleEmailSubmit(String email, String password) async {
    final controller = ref.read(authControllerProvider.notifier);
    final success = _isRegisterMode
        ? await controller.register(email, password)
        : await controller.signInWithEmail(email, password);

    if (success && mounted) {
      context.go(RouteNames.home);
    } else if (mounted) {
      final state = ref.read(authControllerProvider);
      if (state.errorMessage != null) {
        final l10n = AppLocalizations.of(context)!;
        ErrorSnackbar.showError(context, _localizeAuthError(state.errorMessage!, l10n));
      }
    }
  }

  Future<void> _handleAnonymous() async {
    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.signInAnonymously();
    if (success && mounted) {
      context.go(RouteNames.home);
    } else if (mounted) {
      final state = ref.read(authControllerProvider);
      if (state.errorMessage != null) {
        final l10n = AppLocalizations.of(context)!;
        ErrorSnackbar.showError(context, _localizeAuthError(state.errorMessage!, l10n));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF04080F), Color(0xFF0D1B2A), Color(0xFF0D1B2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                // Logo + title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.orange.withValues(alpha: 0.25),
                              AppColors.deepNavy,
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.orange.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orange.withValues(alpha: 0.3),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield,
                          size: 44,
                          color: AppColors.orange,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.authWelcomeTo,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.authAppName,
                        style: AppTextStyles.displayMedium.copyWith(
                          color: AppColors.orange,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.authContinueJourney,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                if (!_showEmailForm) ...[
                  // Social login buttons
                  _SocialButton(
                    label: l10n.authGoogleSignIn,
                    icon: Icons.g_mobiledata,
                    iconColor: const Color(0xFFEA4335),
                    onTap: isLoading
                        ? null
                        : () {
                            // Google sign-in not yet implemented
                            ErrorSnackbar.showError(
                              context,
                              l10n.authComingSoon,
                            );
                          },
                  ),
                  const SizedBox(height: 12),
                  _SocialButton(
                    label: l10n.authAppleSignIn,
                    icon: Icons.apple,
                    iconColor: AppColors.textWhite,
                    onTap: isLoading
                        ? null
                        : () {
                            ErrorSnackbar.showError(
                              context,
                              l10n.authComingSoon,
                            );
                          },
                  ),
                  const SizedBox(height: 20),

                  // OR divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(l10n.authOr, style: AppTextStyles.labelSmall),
                      ),
                      const Expanded(child: Divider(color: AppColors.divider)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sign Up with Email (primary CTA)
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => setState(() {
                              _showEmailForm = true;
                              _isRegisterMode = true;
                            }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.authSignUpEmail,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Log In link
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => setState(() {
                              _showEmailForm = true;
                              _isRegisterMode = false;
                            }),
                    child: Text(
                      l10n.authLogIn,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Continue as Guest
                  isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.orange,
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: _handleAnonymous,
                          child: Text(
                            l10n.authContinueGuest,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.textMuted,
                            ),
                          ),
                        ),

                  // Guest data warning
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF664D00).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.amber.shade700.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber,
                            color: Colors.amber.shade400, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.authGuestWarning,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.amber.shade200,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Email form (register or login)
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() => _showEmailForm = false),
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.textSecondary),
                      ),
                      Text(
                        _isRegisterMode ? l10n.authCreateAccount : l10n.authSignIn,
                        style: AppTextStyles.headlineMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Toggle Register/Login
                  Row(
                    children: [
                      _TabToggle(
                        label: l10n.authSignIn,
                        isSelected: !_isRegisterMode,
                        onTap: () =>
                            setState(() => _isRegisterMode = false),
                      ),
                      const SizedBox(width: 12),
                      _TabToggle(
                        label: l10n.authRegister,
                        isSelected: _isRegisterMode,
                        onTap: () =>
                            setState(() => _isRegisterMode = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  LoginForm(
                    isRegisterMode: _isRegisterMode,
                    onSubmit: _handleEmailSubmit,
                    isLoading: isLoading,
                  ),
                ],

                const SizedBox(height: 32),
                Center(
                  child: Text(
                    l10n.authTerms,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.orange : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.orange : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
