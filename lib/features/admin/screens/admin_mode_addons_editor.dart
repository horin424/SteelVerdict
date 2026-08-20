import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../services/game_config/game_config_providers.dart';

class AdminModeAddonsEditor extends ConsumerStatefulWidget {
  const AdminModeAddonsEditor({super.key});

  @override
  ConsumerState<AdminModeAddonsEditor> createState() => _AdminModeAddonsEditorState();
}

class _AdminModeAddonsEditorState extends ConsumerState<AdminModeAddonsEditor> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;
  bool _initialized = false;

  static const _defaultModes = [
    'practice', 'normal', 'tabletop', 'epic', 'boss', 'history_puzzle', 'pvp',
  ];

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllers(Map<String, String> addons) {
    if (_initialized) return;
    _initialized = true;
    // Ensure all default modes have entries
    for (final mode in _defaultModes) {
      _controllers[mode] = TextEditingController(text: addons[mode] ?? '');
    }
    // Add any custom modes from config
    for (final entry in addons.entries) {
      if (!_controllers.containsKey(entry.key)) {
        _controllers[entry.key] = TextEditingController(text: entry.value);
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final modeAddons = <String, String>{};
      for (final entry in _controllers.entries) {
        if (entry.value.text.isNotEmpty) {
          modeAddons[entry.key] = entry.value.text;
        }
      }
      await FirebaseFirestore.instance
          .collection(AppConstants.firestoreSystemConfig)
          .doc(AppConstants.firestoreGameConfig)
          .set({'mode_addons': modeAddons}, SetOptions(merge: true));
      if (mounted) ErrorSnackbar.showSuccess(context, l10n.adminSaveSuccess);
    } catch (e) {
      if (mounted) ErrorSnackbar.showError(context, l10n.adminSaveError(e.toString()));
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(gameConfigProvider);
    _initControllers(config.modeAddons);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(l10n.adminModeAddons, style: AppTextStyles.headlineMedium),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: _controllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.key,
                          style: AppTextStyles.labelMedium.copyWith(color: AppColors.goldAccent),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: entry.value,
                        maxLines: 4,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontSize: 12),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.cardSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.goldAccent),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
