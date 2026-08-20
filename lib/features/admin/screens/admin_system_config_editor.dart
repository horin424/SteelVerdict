import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../services/game_config/game_config_providers.dart';

class AdminSystemConfigEditor extends ConsumerStatefulWidget {
  const AdminSystemConfigEditor({super.key});

  @override
  ConsumerState<AdminSystemConfigEditor> createState() =>
      _AdminSystemConfigEditorState();
}

class _AdminSystemConfigEditorState
    extends ConsumerState<AdminSystemConfigEditor> {
  final _fallbackPromptController = TextEditingController();
  final _adRewardedController = TextEditingController();
  final _adInterstitialController = TextEditingController();
  final _newUidController = TextEditingController();
  List<String> _devUids = [];
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _fallbackPromptController.dispose();
    _adRewardedController.dispose();
    _adInterstitialController.dispose();
    _newUidController.dispose();
    super.dispose();
  }

  void _initFromConfig() {
    if (_initialized) return;
    _initialized = true;
    final config = ref.read(gameConfigProvider);
    _fallbackPromptController.text = config.fallbackPrompt ?? '';
    _adRewardedController.text = config.adUnitRewarded;
    _adInterstitialController.text = config.adUnitInterstitial;
    _devUids = List<String>.from(config.devUids);
  }

  void _addUid() {
    final uid = _newUidController.text.trim();
    if (uid.isEmpty || _devUids.contains(uid)) return;
    setState(() {
      _devUids.add(uid);
      _newUidController.clear();
    });
  }

  void _removeUid(String uid) {
    setState(() => _devUids.remove(uid));
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final fallback = _fallbackPromptController.text.trim();
      await FirebaseFirestore.instance
          .collection(AppConstants.firestoreSystemConfig)
          .doc(AppConstants.firestoreGameConfig)
          .set({
        // Write both camelCase (Flutter) and snake_case (Cloud Functions)
        'fallbackPrompt': fallback,
        'fallback_prompt': fallback,
        'devUids': _devUids,
        'dev_uids': _devUids,
        'adUnitRewarded': _adRewardedController.text.trim(),
        'adUnitInterstitial': _adInterstitialController.text.trim(),
      }, SetOptions(merge: true));
      if (mounted) ErrorSnackbar.showSuccess(context, l10n.adminSaveSuccess);
    } catch (e) {
      if (mounted) ErrorSnackbar.showError(context, l10n.adminSaveError(e.toString()));
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(gameConfigProvider);
    _initFromConfig();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text('System Config', style: AppTextStyles.headlineMedium),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Fallback Prompt ──────────────────────────────────────
                _SectionLabel(label: 'FALLBACK PROMPT'),
                _AdminField(
                  label: 'Used when no worldview/scenario prompt is configured',
                  controller: _fallbackPromptController,
                  maxLines: 10,
                ),
                const SizedBox(height: 8),

                // ── Dev UIDs ─────────────────────────────────────────────
                _SectionLabel(label: 'DEV UIDs (admin access)'),
                ..._devUids.map(
                  (uid) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Text(
                              uid,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.defeatRed, size: 20),
                          onPressed: () => _removeUid(uid),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newUidController,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Paste Firebase UID...',
                            hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.cardSurface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderSubtle)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderSubtle)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.goldAccent)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onSubmitted: (_) => _addUid(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addUid,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldAccent,
                          foregroundColor: AppColors.inkBrown,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: Text(l10n.adminAdd, style: AppTextStyles.labelMedium.copyWith(color: AppColors.inkBrown)),
                      ),
                    ],
                  ),
                ),

                // ── Ad Unit IDs ──────────────────────────────────────────
                _SectionLabel(label: 'AD UNIT IDs'),
                _AdminField(
                  label: 'Rewarded Ad Unit ID',
                  controller: _adRewardedController,
                ),
                _AdminField(
                  label: 'Interstitial Ad Unit ID',
                  controller: _adInterstitialController,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: AppColors.inkBrown,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.adminSave, style: AppTextStyles.labelLarge.copyWith(color: AppColors.inkBrown)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 1.5,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _AdminField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _AdminField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.cardSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderSubtle)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderSubtle)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.goldAccent)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
