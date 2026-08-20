import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../services/game_config/game_config_providers.dart';

class AdminWorldviewEditor extends ConsumerStatefulWidget {
  const AdminWorldviewEditor({super.key});

  @override
  ConsumerState<AdminWorldviewEditor> createState() => _AdminWorldviewEditorState();
}

class _AdminWorldviewEditorState extends ConsumerState<AdminWorldviewEditor> {
  String? _selectedKey;
  bool _isSaving = false;

  final _titleController = TextEditingController();
  final _titleJaController = TextEditingController();
  final _judgmentController = TextEditingController();
  final _descController = TextEditingController();
  final _descJaController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _titleJaController.dispose();
    _judgmentController.dispose();
    _descController.dispose();
    _descJaController.dispose();
    super.dispose();
  }

  void _loadWorldview(String key) {
    final config = ref.read(gameConfigProvider);
    final wv = config.worldviews[key];
    if (wv == null) return;
    setState(() => _selectedKey = key);
    _titleController.text = wv.title;
    _titleJaController.text = wv.titleJa ?? '';
    _judgmentController.text = wv.commonJudgment;
    _descController.text = wv.worldviewDescription;
    _descJaController.text = wv.worldviewDescriptionJa ?? '';
  }

  Future<void> _save() async {
    if (_selectedKey == null) return;
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.firestoreSystemConfig)
          .doc(AppConstants.firestoreGameConfig)
          .set({
        'worldviews': {
          _selectedKey!: {
            'worldviewKey': _selectedKey,
            'title': _titleController.text,
            'titleJa': _titleJaController.text,
            'commonJudgment': _judgmentController.text,
            'worldviewDescription': _descController.text,
            'worldviewDescriptionJa': _descJaController.text,
            // Preserve existing stats and statDescriptions
            'stats': ref.read(gameConfigProvider).worldviews[_selectedKey]?.stats ?? [],
            'statDescriptions': ref.read(gameConfigProvider).worldviews[_selectedKey]?.statDescriptions ?? {},
          },
        },
      }, SetOptions(merge: true));
      if (mounted) ErrorSnackbar.showSuccess(context, l10n.adminSaveSuccess);
    } catch (e) {
      if (mounted) ErrorSnackbar.showError(context, l10n.adminSaveError(e.toString()));
    }
    setState(() => _isSaving = false);
  }

  Future<void> _addWorldview() async {
    final l10n = AppLocalizations.of(context)!;
    final keyController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navyMid,
        title: Text(l10n.adminNewWorldview, style: AppTextStyles.headlineSmall),
        content: TextField(
          controller: keyController,
          style: AppTextStyles.bodySmall,
          decoration: InputDecoration(
            hintText: 'e.g. cyberpunk_2099',
            hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.goldAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: AppTextStyles.labelMedium),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, keyController.text.trim()),
            child: Text(l10n.adminAdd, style: AppTextStyles.labelMedium.copyWith(color: AppColors.goldAccent)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.firestoreSystemConfig)
            .doc(AppConstants.firestoreGameConfig)
            .set({
          'worldviews': {
            result: {
              'worldviewKey': result,
              'title': result,
              'titleJa': '',
              'commonJudgment': '',
              'worldviewDescription': '',
              'worldviewDescriptionJa': '',
              'stats': ['strength', 'intellect', 'skill', 'magic', 'art', 'life'],
              'statDescriptions': {},
            },
          },
        }, SetOptions(merge: true));
        if (mounted) {
          _loadWorldview(result);
        }
      } catch (e) {
        if (mounted) ErrorSnackbar.showError(context, l10n.adminSaveError(e.toString()));
      }
    }
  }

  Future<void> _deleteWorldview(String key) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navyMid,
        title: Text(l10n.adminDelete, style: AppTextStyles.headlineSmall),
        content: Text(l10n.adminDeleteConfirm, style: AppTextStyles.bodySmall),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel, style: AppTextStyles.labelMedium)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.adminDelete, style: AppTextStyles.labelMedium.copyWith(color: AppColors.defeatRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.firestoreSystemConfig)
            .doc(AppConstants.firestoreGameConfig)
            .update({'worldviews.$key': FieldValue.delete()});
        setState(() => _selectedKey = null);
      } catch (e) {
        if (mounted) ErrorSnackbar.showError(context, l10n.adminSaveError(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(gameConfigProvider);
    final worldviews = config.worldviews;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(l10n.adminWorldviews, style: AppTextStyles.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.goldAccent),
            onPressed: _addWorldview,
          ),
        ],
      ),
      body: Row(
        children: [
          // Left: worldview list
          SizedBox(
            width: 160,
            child: Container(
              color: AppColors.navyMid,
              child: ListView(
                children: worldviews.keys.map((key) {
                  final isSelected = key == _selectedKey;
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: AppColors.goldAccent.withValues(alpha: 0.1),
                    title: Text(
                      key,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.defeatRed),
                      onPressed: () => _deleteWorldview(key),
                    ),
                    onTap: () => _loadWorldview(key),
                  );
                }).toList(),
              ),
            ),
          ),
          // Right: editor form
          Expanded(
            child: _selectedKey == null
                ? Center(
                    child: Text(
                      'Select a worldview to edit',
                      style: AppTextStyles.bodySmall,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _AdminField(label: l10n.adminTitle, controller: _titleController),
                      _AdminField(label: l10n.adminTitleJa, controller: _titleJaController),
                      _AdminField(label: l10n.adminCommonJudgment, controller: _judgmentController, maxLines: 8),
                      _AdminField(label: l10n.adminDescription, controller: _descController, maxLines: 5),
                      _AdminField(label: l10n.adminDescriptionJa, controller: _descJaController, maxLines: 5),
                      const SizedBox(height: 20),
                      ElevatedButton(
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
                    ],
                  ),
          ),
        ],
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
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
