import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/mode_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../services/game_config/game_config_providers.dart';

/// The model keys the server reads, and the model it uses when a key is not
/// set (functions/src/utils/config.ts and ai.ts). They are always listed: the
/// editor used to list only the keys already stored, so a model that had been
/// removed could never be set again (B25).
const serverModelDefaults = {
  'gemini_flash_lite': 'gemini-2.5-flash-lite',
  'gemini_flash': 'gemini-2.5-flash',
  'claude': 'claude-haiku-4-5-20251001',
};

/// The model keys to list: the server's, then any other key already stored.
List<String> modelKeysToList(Map<String, String> stored) =>
    {...serverModelDefaults.keys, ...stored.keys}.toList();

/// What a save writes. A typed model is set; an emptied one is removed, so the
/// server falls back to its default. Leaving it out of the merged write kept
/// the old model in place.
({Map<String, String> set, Set<String> remove}) modelChanges(Map<String, String> typed) {
  final set = <String, String>{};
  final remove = <String>{};
  typed.forEach((key, value) {
    final model = value.trim();
    if (model.isEmpty) {
      remove.add(key);
    } else {
      set[key] = model;
    }
  });
  return (set: set, remove: remove);
}

class AdminCostsEditor extends ConsumerStatefulWidget {
  const AdminCostsEditor({super.key});

  @override
  ConsumerState<AdminCostsEditor> createState() => _AdminCostsEditorState();
}

class _AdminCostsEditorState extends ConsumerState<AdminCostsEditor> {
  final Map<String, TextEditingController> _costControllers = {};
  final Map<String, TextEditingController> _modelControllers = {};
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    for (final c in _costControllers.values) {
      c.dispose();
    }
    for (final c in _modelControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllers(Map<String, int> costs, Map<String, String> models) {
    if (_initialized) return;
    _initialized = true;
    for (final entry in costs.entries) {
      _costControllers[entry.key] = TextEditingController(text: entry.value.toString());
    }
    for (final key in modelKeysToList(models)) {
      _modelControllers[key] = TextEditingController(text: models[key] ?? '');
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final ticketCosts = <String, int>{};
      for (final entry in _costControllers.entries) {
        ticketCosts[entry.key] = int.tryParse(entry.value.text) ?? 0;
      }
      final changes = modelChanges({
        for (final entry in _modelControllers.entries) entry.key: entry.value.text,
      });
      final modelConfig = <String, Object>{
        ...changes.set,
        for (final key in changes.remove) key: FieldValue.delete(),
      };
      await FirebaseFirestore.instance
          .collection(AppConstants.firestoreSystemConfig)
          .doc(AppConstants.firestoreGameConfig)
          .set({
        'ticket_costs': ticketCosts,
        'model_config': modelConfig,
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
    final config = ref.watch(gameConfigProvider);
    _initControllers(config.ticketCosts, config.modelConfig);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(l10n.adminCosts, style: AppTextStyles.headlineMedium),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Ticket costs section
                Text(
                  l10n.adminTicketCostsSection,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.5,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                ..._costControllers.entries.map((entry) => _CostRow(
                  label: localizedModeName(entry.key, l10n),
                  controller: entry.value,
                )),
                const SizedBox(height: 24),

                // Model config section
                Text(
                  l10n.adminAiModelsSection,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.5,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                ..._modelControllers.entries.map((entry) => _ModelRow(
                  label: localizedModeName(entry.key, l10n),
                  controller: entry.value,
                  hint: serverModelDefaults[entry.key],
                )),
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

class _CostRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _CostRow({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.goldAccent),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.confirmation_number, size: 16, color: AppColors.goldAccent),
        ],
      ),
    );
  }
}

class _ModelRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  /// Shown when empty: the model the server uses when none is set.
  final String? hint;

  const _ModelRow({required this.label, required this.controller, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 12),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
