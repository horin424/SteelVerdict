import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../features/splash/splash_providers.dart';
import '../../../services/game_config/game_config_providers.dart';
import '../settings_providers.dart';
import '../widgets/language_selector.dart';
import '../../../models/user_model.dart';

String _tierDisplayName(SubscriptionTier tier, AppLocalizations l10n) {
  switch (tier) {
    case SubscriptionTier.free:
      return l10n.subscriptionFree;
    case SubscriptionTier.sub500:
      return l10n.subscriptionCommanderPrice;
    case SubscriptionTier.sub1000:
      return l10n.subscriptionGeneralPrice;
    case SubscriptionTier.sub3000:
      return l10n.subscriptionWarlordPrice;
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final userAsync = ref.watch(currentUserModelProvider);
    final authState = ref.watch(authStateChangesProvider);
    final isAnonymous = authState.valueOrNull?.isAnonymous ?? false;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: AppColors.deepNavy,
            pinned: true,
            elevation: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.settingsProfile, style: AppTextStyles.headlineMedium),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    l10n.settingsEdit,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ],
            ),
            automaticallyImplyLeading: false,
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header card
                userAsync.when(
                  data: (user) => _ProfileHeader(
                    user: user,
                    isAnonymous: isAnonymous,
                    onLinkAccount: () => context.push(RouteNames.accountLink),
                    onShop: () => context.push(RouteNames.shop),
                  ),
                  loading: () => const SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.orange),
                    ),
                  ),
                  error: (e, st) => _ProfileHeader(
                    user: null,
                    isAnonymous: isAnonymous,
                    onLinkAccount: () => context.push(RouteNames.accountLink),
                    onShop: () => context.push(RouteNames.shop),
                  ),
                ),

                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ACCOUNT section
                      _SectionLabel(label: l10n.settingsAccount),
                      const SizedBox(height: 10),
                      _SettingsGroup(
                        children: [
                          _SettingRow(
                            icon: Icons.person_outline,
                            iconColor: AppColors.blue,
                            title: l10n.settingsPersonalInfo,
                            onTap: () {
                              ErrorSnackbar.showError(
                                context,
                                l10n.settingsComingSoon,
                              );
                            },
                          ),
                          _Divider(),
                          _SettingRow(
                            icon: Icons.lock_outline,
                            iconColor: AppColors.purple,
                            title: l10n.settingsChangePassword,
                            onTap: isAnonymous
                                ? () => ErrorSnackbar.showError(
                                    context,
                                    l10n.settingsLinkAccountFirst,
                                  )
                                : () => ErrorSnackbar.showError(
                                    context,
                                    l10n.settingsComingSoon,
                                  ),
                          ),
                          _Divider(),
                          _SettingRow(
                            icon: Icons.link,
                            iconColor: AppColors.teal,
                            title: l10n.settingsLinkedAccounts,
                            subtitle: isAnonymous
                                ? l10n.settingsGuestAccount
                                : l10n.authEmail,
                            onTap: isAnonymous
                                ? () => context.push(RouteNames.accountLink)
                                : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // PREFERENCES section
                      _SectionLabel(label: l10n.settingsPreferences),
                      const SizedBox(height: 10),
                      _SettingsGroup(
                        children: [
                          _ToggleRow(
                            icon: Icons.notifications_outlined,
                            iconColor: AppColors.orange,
                            title: l10n.settingsNotifications,
                            value: settingsState.notificationsEnabled,
                            onChanged: (v) =>
                                settingsController.setNotifications(v),
                          ),
                          _Divider(),
                          _ToggleRow(
                            icon: Icons.volume_up_outlined,
                            iconColor: AppColors.blue,
                            title: l10n.settingsSoundMusic,
                            value: settingsState.soundEnabled,
                            onChanged: (v) => settingsController.setSound(v),
                          ),
                          if (settingsState.soundEnabled) ...[
                            _Divider(),
                            _VolumeSliderRow(
                              icon: Icons.music_note_outlined,
                              iconColor: AppColors.purple,
                              title: l10n.settingsBgmVolume,
                              value: settingsState.bgmVolume,
                              onChanged: (v) =>
                                  settingsController.setBgmVolume(v),
                            ),
                            _Divider(),
                            _VolumeSliderRow(
                              icon: Icons.speaker_outlined,
                              iconColor: AppColors.teal,
                              title: l10n.settingsSfxVolume,
                              value: settingsState.sfxVolume,
                              onChanged: (v) =>
                                  settingsController.setSfxVolume(v),
                            ),
                          ],
                          _Divider(),
                          _LanguageRow(
                            currentCode: locale.languageCode,
                            onTap: () => _showLanguageSheet(
                              context,
                              ref,
                              locale.languageCode,
                              settingsController,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // SUPPORT section
                      _SectionLabel(label: l10n.settingsSupport),
                      const SizedBox(height: 10),
                      _SettingsGroup(
                        children: [
                          _SettingRow(
                            icon: Icons.help_outline,
                            iconColor: AppColors.goldAccent,
                            title: l10n.settingsHelpCenter,
                            onTap: () => context.push(RouteNames.helpCenter),
                          ),
                          _Divider(),
                          _SettingRow(
                            icon: Icons.privacy_tip_outlined,
                            iconColor: AppColors.textSecondary,
                            title: l10n.settingsPrivacyPolicy,
                            onTap: () => context.push(RouteNames.privacyPolicy),
                          ),
                          _Divider(),
                          _SettingRow(
                            icon: Icons.delete_outline,
                            iconColor: AppColors.defeatRed,
                            title: l10n.settingsClearData,
                            isDestructive: true,
                            isLoading: settingsState.isClearingData,
                            onTap: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) {
                                  final controller = TextEditingController();
                                  final confirmWord = l10n.deleteConfirmWord;
                                  return StatefulBuilder(
                                    builder: (ctx, setState) => AlertDialog(
                                      backgroundColor: AppColors.navyMid,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text(
                                        l10n.settingsClearData,
                                        style: AppTextStyles.headlineSmall,
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.settingsClearDataConfirm,
                                            style: AppTextStyles.bodySmall,
                                          ),
                                          const SizedBox(height: 16),
                                          TextField(
                                            controller: controller,
                                            autofocus: true,
                                            style: AppTextStyles.bodySmall,
                                            decoration: InputDecoration(
                                              hintText: l10n.deleteConfirmHint,
                                              hintStyle: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color: AppColors.textMuted,
                                                  ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: AppColors.defeatRed,
                                                ),
                                              ),
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text(
                                            l10n.cancel,
                                            style: AppTextStyles.labelMedium,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed:
                                              controller.text == confirmWord
                                              ? () => Navigator.pop(ctx, true)
                                              : null,
                                          child: Text(
                                            l10n.delete,
                                            style: AppTextStyles.labelMedium
                                                .copyWith(
                                                  color:
                                                      controller.text ==
                                                          confirmWord
                                                      ? AppColors.defeatRed
                                                      : AppColors.textMuted,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                              if (confirmed == true && context.mounted) {
                                final success = await settingsController
                                    .clearAllData();
                                if (success && context.mounted) {
                                  ErrorSnackbar.showSuccess(
                                    context,
                                    l10n.settingsAllDataCleared,
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // RACE section
                      _SectionLabel(label: l10n.settingsRace),
                      const SizedBox(height: 10),
                      _RaceCard(l10n: l10n),
                      if (ref.watch(currentRaceProvider) != null) ...[
                        const SizedBox(height: 10),
                        _SettingsGroup(
                          children: [
                            _SettingRow(
                              icon: Icons.shield_outlined,
                              iconColor: AppColors.goldAccent,
                              title: l10n.settingsChangeRace,
                              isDestructive: true,
                              onTap: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) {
                                    final controller = TextEditingController();
                                    final confirmWord = l10n.deleteConfirmWord;
                                    return StatefulBuilder(
                                      builder: (ctx, setState) => AlertDialog(
                                        backgroundColor: AppColors.navyMid,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        title: Text(
                                          l10n.settingsChangeRace,
                                          style: AppTextStyles.headlineSmall,
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.settingsChangeRaceConfirm,
                                              style: AppTextStyles.bodySmall,
                                            ),
                                            const SizedBox(height: 16),
                                            TextField(
                                              controller: controller,
                                              autofocus: true,
                                              style: AppTextStyles.bodySmall,
                                              decoration: InputDecoration(
                                                hintText:
                                                    l10n.deleteConfirmHint,
                                                hintStyle: AppTextStyles
                                                    .bodySmall
                                                    .copyWith(
                                                      color:
                                                          AppColors.textMuted,
                                                    ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            AppColors.textMuted,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            AppColors.defeatRed,
                                                      ),
                                                    ),
                                              ),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: Text(
                                              l10n.cancel,
                                              style: AppTextStyles.labelMedium,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed:
                                                controller.text == confirmWord
                                                ? () => Navigator.pop(ctx, true)
                                                : null,
                                            child: Text(
                                              l10n.delete,
                                              style: AppTextStyles.labelMedium
                                                  .copyWith(
                                                    color:
                                                        controller.text ==
                                                            confirmWord
                                                        ? AppColors.defeatRed
                                                        : AppColors.textMuted,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                                if (confirmed == true && context.mounted) {
                                  final storage = ref.read(
                                    hiveStorageServiceProvider,
                                  );
                                  await storage.deleteRace();
                                  ref.invalidate(currentRaceProvider);
                                }
                              },
                            ),
                          ],
                        ),
                      ], // end if race != null

                      const SizedBox(height: 20),

                      // Sign out
                      _SettingsGroup(
                        children: [
                          _SettingRow(
                            icon: Icons.logout,
                            iconColor: AppColors.defeatRed,
                            title: l10n.settingsSignOut,
                            isDestructive: true,
                            onTap: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.navyMid,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Text(
                                    l10n.settingsSignOut,
                                    style: AppTextStyles.headlineSmall,
                                  ),
                                  content: Text(
                                    l10n.settingsSignOutConfirm,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text(
                                        l10n.cancel,
                                        style: AppTextStyles.labelMedium,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(
                                        l10n.settingsSignOut,
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                              color: AppColors.defeatRed,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true && context.mounted) {
                                final controller = ref.read(
                                  authControllerProvider.notifier,
                                );
                                await controller.signOut();
                                if (context.mounted) {
                                  context.go(RouteNames.auth);
                                }
                              }
                            },
                          ),
                        ],
                      ),

                      // TEMP: UID debug display
                      const SizedBox(height: 20),
                      Builder(builder: (context) {
                        final myUid = authState.valueOrNull?.uid ?? 'not logged in';
                        final streamValue = ref.watch(gameConfigStreamProvider);
                        final streamState = streamValue.when(
                          data: (c) => 'data: devUids=${c.devUids}',
                          loading: () => 'LOADING...',
                          error: (e, _) => 'ERROR: $e',
                        );
                        final config = ref.watch(gameConfigProvider);
                        final isMatch = config.devUids.contains(myUid);
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DEBUG', style: TextStyle(color: Colors.red, fontSize: 11)),
                              SelectableText('UID: $myUid', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              SelectableText('Stream: $streamState', style: const TextStyle(color: Colors.yellow, fontSize: 11)),
                              Text('Match: $isMatch', style: TextStyle(color: isMatch ? Colors.green : Colors.red, fontSize: 11)),
                            ],
                          ),
                        );
                      }),

                      // ADMIN section (only visible to admin users)
                      if (ref.watch(isAdminProvider)) ...[
                        const SizedBox(height: 20),
                        _SectionLabel(label: l10n.adminPanel),
                        const SizedBox(height: 10),
                        _SettingsGroup(
                          children: [
                            _SettingRow(
                              icon: Icons.admin_panel_settings,
                              iconColor: AppColors.goldAccent,
                              title: l10n.adminPanel,
                              onTap: () => context.push(RouteNames.adminPanel),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          l10n.settingsVersion,
                          style: AppTextStyles.labelSmall,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(
    BuildContext context,
    WidgetRef ref,
    String currentCode,
    dynamic settingsController,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.settingsSelectLanguage,
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 20),
            LanguageSelector(
              currentLanguageCode: currentCode,
              onChanged: (code) async {
                await settingsController.setLocale(code);
                if (context.mounted) {
                  Navigator.pop(context);
                  ErrorSnackbar.showSuccess(
                    context,
                    AppLocalizations.of(context)!.settingsLanguageChanged,
                  );
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ──────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserModel? user;
  final bool isAnonymous;
  final VoidCallback onLinkAccount;
  final VoidCallback onShop;

  const _ProfileHeader({
    required this.user,
    required this.isAnonymous,
    required this.onLinkAccount,
    required this.onShop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2D3D), Color(0xFF253545)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.orange.withValues(alpha: 0.8),
                  AppColors.purple,
                ],
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ??
                      AppLocalizations.of(context)!.anonymousCommander,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.orange.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isAnonymous
                            ? AppLocalizations.of(context)!.subscriptionFree
                            : _tierDisplayName(
                                user?.subscriptionTier ?? SubscriptionTier.free,
                                AppLocalizations.of(context)!,
                              ),
                        style: TextStyle(
                          color: AppColors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isAnonymous) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onLinkAccount,
                        child: Text(
                          AppLocalizations.of(context)!.settingsLinkAccount,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.amber.shade400,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.amber.shade400,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.confirmation_number,
                      color: AppColors.goldAccent,
                      value: '${user?.ticketCount ?? 0}',
                      label: AppLocalizations.of(context)!.tickets,
                    ),
                    const SizedBox(width: 16),
                    _MiniStat(
                      icon: Icons.emoji_events,
                      color: AppColors.victoryGreen,
                      value: '${user?.totalWins ?? 0}',
                      label: AppLocalizations.of(context)!.homeWins,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Daily reward badge
          GestureDetector(
            onTap: onShop,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.goldAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: AppColors.goldAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.shopTitle,
                  style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textMuted,
        letterSpacing: 1.5,
        fontSize: 11,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.borderSubtle,
      indent: 56,
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final bool isLoading;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDestructive
        ? AppColors.defeatRed
        : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: titleColor,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.orange,
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textMuted,
                  size: 13,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(fontSize: 14),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.orange,
            activeTrackColor: AppColors.orange.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.borderSubtle,
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String currentCode;
  final VoidCallback onTap;

  const _LanguageRow({required this.currentCode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langLabel = currentCode == 'ja'
        ? l10n.settingsLangJapanese
        : l10n.settingsLangEnglish;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.language,
                  color: AppColors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n.settingsLanguage,
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 14),
                ),
              ),
              Text(
                langLabel,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textMuted,
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VolumeSliderRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeSliderRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Text(title, style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.goldAccent,
                inactiveTrackColor: AppColors.borderSubtle,
                thumbColor: AppColors.goldAccent,
                overlayColor: AppColors.goldAccent.withValues(alpha: 0.15),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: value,
                min: 0.0,
                max: 1.0,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${(value * 100).round()}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── My Race Card ─────────────────────────────────────────────────────────────

class _RaceCard extends ConsumerWidget {
  final AppLocalizations l10n;
  const _RaceCard({required this.l10n});

  String _statLabel(String key) {
    switch (key) {
      case 'strength':
        return l10n.statStrength;
      case 'intellect':
        return l10n.statIntellect;
      case 'skill':
        return l10n.statSkill;
      case 'magic':
        return l10n.statMagic;
      case 'art':
        return l10n.statArt;
      case 'life':
        return l10n.statLife;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final race = ref.watch(currentRaceProvider);

    if (race == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              color: AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(l10n.settingsViewRaceNoRace, style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.shield,
                  color: AppColors.goldAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      race.raceName,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.goldAccent,
                        fontSize: 15,
                      ),
                    ),
                    if (race.overview.isNotEmpty)
                      Text(
                        race.overview,
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: race.stats.entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.navyMid,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _statLabel(e.key),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${e.value}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textWhite,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
