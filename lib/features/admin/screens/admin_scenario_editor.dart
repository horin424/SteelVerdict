import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../../../core/utils/stat_names.dart';
import '../../../models/scenario_model.dart';
import '../../../services/game_config/game_config_providers.dart';

const _kDefaultStatKeys = [
  'strength',
  'intellect',
  'skill',
  'magic',
  'art',
  'life',
];

/// Label for one row in the scenario list.
///
/// Uses the localized title so the Japanese build reads Japanese, and falls
/// back to the raw scenario id when a scenario has no usable title in either
/// language — a half-filled entry should still be selectable, not an empty row.
/// Display name for a battle type, reusing the strings players already see on
/// the battle-type screen rather than showing the raw enum name.
String _battleTypeName(String type, AppLocalizations l10n) {
  switch (type) {
    case 'standard':
      return l10n.battleTypeStandard;
    case 'boss':
      return l10n.battleTypeBoss;
    case 'history':
      return l10n.battleTypeHistory;
    default:
      return type;
  }
}

String _listLabel(ScenarioModel s, String locale, String id) {
  final title = s.localizedTitle(locale);
  return title.isNotEmpty ? title : id;
}

class AdminScenarioEditor extends ConsumerStatefulWidget {
  const AdminScenarioEditor({super.key});

  @override
  ConsumerState<AdminScenarioEditor> createState() => _AdminScenarioEditorState();
}

class _AdminScenarioEditorState extends ConsumerState<AdminScenarioEditor> {
  String? _selectedId;
  bool _isSaving = false;

  final _titleController = TextEditingController();
  final _titleJaController = TextEditingController();
  final _enemyNameController = TextEditingController();
  final _enemyNameJaController = TextEditingController();
  final _commanderDefController = TextEditingController();
  final _commanderDefJaController = TextEditingController();
  final _difficultyController = TextEditingController();
  String _battleType = 'standard';
  bool _isFree = false;
  String _worldviewKey = AppConstants.defaultWorldviewKey;
  Map<String, TextEditingController> _enemyStatControllers = {};

  @override
  void dispose() {
    _titleController.dispose();
    _titleJaController.dispose();
    _enemyNameController.dispose();
    _enemyNameJaController.dispose();
    _commanderDefController.dispose();
    _commanderDefJaController.dispose();
    _difficultyController.dispose();
    for (final c in _enemyStatControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initEnemyStatControllers(Map<String, int> existingStats) {
    for (final c in _enemyStatControllers.values) {
      c.dispose();
    }
    final statKeys = existingStats.isNotEmpty ? existingStats.keys.toList() : _kDefaultStatKeys;
    _enemyStatControllers = {
      for (final key in statKeys)
        key: TextEditingController(text: (existingStats[key] ?? 0).toString()),
    };
  }

  void _loadScenario(String id) {
    final config = ref.read(gameConfigProvider);
    final s = config.scenarios[id];
    if (s == null) return;
    setState(() {
      _selectedId = id;
      _battleType = s.battleType.name;
      _isFree = s.isFree;
      _worldviewKey = s.worldviewKey.isNotEmpty ? s.worldviewKey : AppConstants.defaultWorldviewKey;
    });
    _titleController.text = s.title;
    _titleJaController.text = s.titleJa ?? '';
    _enemyNameController.text = s.enemyName;
    _enemyNameJaController.text = s.enemyNameJa ?? '';
    _commanderDefController.text = s.commanderDefinition;
    _commanderDefJaController.text = s.commanderDefinitionJa ?? '';
    _difficultyController.text = s.difficulty.toString();
    setState(() => _initEnemyStatControllers(s.enemyStats));
  }

  Future<void> _save() async {
    if (_selectedId == null) return;
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final config = ref.read(gameConfigProvider);
      final existing = config.scenarios[_selectedId];
      final enemyStats = <String, int>{};
      for (final entry in _enemyStatControllers.entries) {
        enemyStats[entry.key] = int.tryParse(entry.value.text) ?? 0;
      }
      await FirebaseFirestore.instance
          .collection(AppConstants.firestoreSystemConfig)
          .doc(AppConstants.firestoreGameConfig)
          .set({
        'scenarios': {
          _selectedId!: {
            'scenarioId': _selectedId,
            'title': _titleController.text,
            'titleJa': _titleJaController.text,
            'enemyName': _enemyNameController.text,
            'enemyNameJa': _enemyNameJaController.text,
            'commanderDefinition': _commanderDefController.text,
            'commanderDefinitionJa': _commanderDefJaController.text,
            // Also written in snake_case: prompt.ts reads
            //   scenario.commander_definition ?? scenario.commanderDefinition
            // so on a seeded scenario the snake value won and edits made here
            // never reached the AI. Same reason as the worldview editor.
            'commander_definition': _commanderDefController.text,
            'commander_definition_ja': _commanderDefJaController.text,
            'difficulty': int.tryParse(_difficultyController.text) ?? 1,
            'battleType': _battleType,
            'isFree': _isFree,
            'worldviewKey': _worldviewKey,
            'isUnlocked': existing?.isUnlocked ?? true,
            'enemyStats': enemyStats,
          },
        },
      }, SetOptions(merge: true));
      if (mounted) ErrorSnackbar.showSuccess(context, l10n.adminSaveSuccess);
    } catch (e) {
      if (mounted) ErrorSnackbar.showError(context, l10n.adminSaveError(e.toString()));
    }
    setState(() => _isSaving = false);
  }

  Future<void> _addScenario() async {
    final l10n = AppLocalizations.of(context)!;
    final keyController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navyMid,
        title: Text(l10n.adminNewScenario, style: AppTextStyles.headlineSmall),
        content: TextField(
          controller: keyController,
          style: AppTextStyles.bodySmall,
          decoration: InputDecoration(
            hintText: l10n.adminScenarioIdHint,
            hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.goldAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel, style: AppTextStyles.labelMedium)),
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
          'scenarios': {
            result: {
              'scenarioId': result,
              'title': result,
              'titleJa': '',
              'enemyName': '',
              'enemyNameJa': '',
              'commanderDefinition': '',
              'commanderDefinitionJa': '',
              'commander_definition': '',
              'commander_definition_ja': '',
              'difficulty': 1,
              'battleType': 'standard',
              'isFree': false,
              'worldviewKey': AppConstants.defaultWorldviewKey,
              'isUnlocked': true,
              'enemyStats': {for (final k in _kDefaultStatKeys) k: 0},
            },
          },
        }, SetOptions(merge: true));
        if (mounted) _loadScenario(result);
      } catch (e) {
        if (mounted) ErrorSnackbar.showError(context, l10n.adminSaveError(e.toString()));
      }
    }
  }

  Future<void> _deleteScenario(String key) async {
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
            .update({'scenarios.$key': FieldValue.delete()});
        setState(() => _selectedId = null);
      } catch (e) {
        if (mounted) ErrorSnackbar.showError(context, l10n.adminSaveError(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final config = ref.watch(gameConfigProvider);
    final scenarios = config.scenarios;
    final worldviewKeys = config.worldviews.keys.toList();
    if (worldviewKeys.isEmpty) worldviewKeys.add(AppConstants.defaultWorldviewKey);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(l10n.adminScenarios, style: AppTextStyles.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.goldAccent),
            onPressed: _addScenario,
          ),
        ],
      ),
      body: Row(
        children: [
          // Left: scenario list
          SizedBox(
            width: 160,
            child: Container(
              color: AppColors.navyMid,
              child: ListView(
                children: scenarios.keys.map((id) {
                  final isSelected = id == _selectedId;
                  final s = scenarios[id]!;
                  return ListTile(
                    dense: true,
                    // A 160px column cannot afford ListTile's default 16px each
                    // side plus IconButton's 48px touch target - that is half
                    // the width gone to chrome, which is why long names wrapped
                    // to four lines. Text now gets the room; the delete button
                    // sits flush right.
                    contentPadding: const EdgeInsets.only(left: 10, right: 2),
                    horizontalTitleGap: 0,
                    minVerticalPadding: 8,
                    selected: isSelected,
                    selectedTileColor: AppColors.goldAccent.withValues(alpha: 0.1),
                    title: Text(
                      // Was s.title, so the list read English in the JA
                      // build while the editor beside it showed Japanese.
                      _listLabel(s, locale, id),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${_battleTypeName(s.battleType.name, l10n)} / ${s.difficulty}',
                      style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.defeatRed),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      visualDensity: VisualDensity.compact,
                      splashRadius: 18,
                      onPressed: () => _deleteScenario(id),
                    ),
                    onTap: () => _loadScenario(id),
                  );
                }).toList(),
              ),
            ),
          ),
          // Right: editor form
          Expanded(
            child: _selectedId == null
                ? Center(child: Text(l10n.adminSelectScenario, style: AppTextStyles.bodySmall))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _AdminField(label: l10n.adminTitle, controller: _titleController),
                      _AdminField(label: l10n.adminTitleJa, controller: _titleJaController),
                      _AdminField(label: l10n.adminEnemyName, controller: _enemyNameController),
                      _AdminField(label: l10n.adminEnemyNameJa, controller: _enemyNameJaController),
                      _AdminField(label: l10n.adminCommanderDef, controller: _commanderDefController, maxLines: 6),
                      _AdminField(label: l10n.adminCommanderDefJa, controller: _commanderDefJaController, maxLines: 6),
                      _AdminField(label: l10n.adminDifficulty, controller: _difficultyController),

                      // Worldview key dropdown
                      _SectionLabel(label: l10n.adminWorldviewSection),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DropdownButtonFormField<String>(
                          value: worldviewKeys.contains(_worldviewKey) ? _worldviewKey : worldviewKeys.first,
                          dropdownColor: AppColors.navyMid,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.cardSurface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderSubtle)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: worldviewKeys
                              .map((k) => DropdownMenuItem(value: k, child: Text(k, style: TextStyle(fontSize: 12))))
                              .toList(),
                          onChanged: (v) => setState(() => _worldviewKey = v ?? AppConstants.defaultWorldviewKey),
                        ),
                      ),

                      // Battle type dropdown
                      _SectionLabel(label: l10n.adminBattleType.toUpperCase()),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DropdownButtonFormField<String>(
                          value: _battleType,
                          dropdownColor: AppColors.navyMid,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.cardSurface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderSubtle)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: ['standard', 'boss', 'history']
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(_battleTypeName(t, l10n)),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _battleType = v ?? 'standard'),
                        ),
                      ),

                      // Free toggle
                      SwitchListTile(
                        value: _isFree,
                        onChanged: (v) => setState(() => _isFree = v),
                        title: Text(l10n.adminFreeScenario, style: AppTextStyles.labelMedium),
                        activeTrackColor: AppColors.goldAccent,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),

                      // Enemy stats section
                      _SectionLabel(label: l10n.adminEnemyStatsSection),
                      ..._enemyStatControllers.entries.map((entry) => _StatRow(
                            // Raw keys before this — the same stat names the
                            // player sees, so they use the same translation.
                            label: localizedStatName(entry.key, l10n),
                            controller: entry.value,
                          )),
                      const SizedBox(height: 12),

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
          fontSize: 10,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _StatRow({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.goldAccent),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.cardSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderSubtle)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderSubtle)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.goldAccent)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
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

  const _AdminField({required this.label, required this.controller, this.maxLines = 1});

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
