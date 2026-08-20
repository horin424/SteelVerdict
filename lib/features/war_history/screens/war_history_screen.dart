import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/error_snackbar.dart';
import '../war_history_providers.dart';
import '../widgets/history_list_tile.dart';
import '../../../models/battle_record_model.dart';

class WarHistoryScreen extends ConsumerStatefulWidget {
  const WarHistoryScreen({super.key});

  @override
  ConsumerState<WarHistoryScreen> createState() => _WarHistoryScreenState();
}

class _WarHistoryScreenState extends ConsumerState<WarHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(battleRecordsProvider);
    final controller = ref.read(warHistoryControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.warHistoryTitle, style: AppTextStyles.headlineMedium),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldAccent,
          labelColor: AppColors.goldAccent,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.warHistorySoloBattles),
            Tab(text: AppLocalizations.of(context)!.warHistoryFavorites),
          ],
        ),
      ),
      body: recordsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldAccent),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.warRed, size: 48),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.warHistoryLoadError(e.toString()), style: AppTextStyles.bodySmall),
              TextButton(
                onPressed: () => ref.invalidate(battleRecordsProvider),
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
        data: (records) {
          final allRecords = records
              .where((r) => r.gameModeEnum != GameMode.practice)
              .toList();
          final favorites = allRecords.where((r) => r.isFavorite).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // All battles tab
              _RecordList(
                records: allRecords,
                onTap: (record) {
                  context.push(
                    RouteNames.warHistoryDetail,
                    extra: {'recordId': record.id},
                  );
                },
                onToggleFavorite: (record) async {
                  final success = await controller.toggleFavorite(record);
                  if (success && context.mounted) {
                    ErrorSnackbar.showSuccess(
                      context,
                      record.isFavorite ? AppLocalizations.of(context)!.favoritesRemoved : AppLocalizations.of(context)!.favoritesAdded,
                    );
                  }
                },
                onRefresh: () async => ref.invalidate(battleRecordsProvider),
                emptyMessage: AppLocalizations.of(context)!.warHistoryEmptyMsg,
              ),
              // Favorites tab
              _RecordList(
                records: favorites,
                onTap: (record) {
                  context.push(
                    RouteNames.warHistoryDetail,
                    extra: {'recordId': record.id},
                  );
                },
                onToggleFavorite: (record) async {
                  await controller.toggleFavorite(record);
                },
                onRefresh: () async => ref.invalidate(battleRecordsProvider),
                emptyMessage: AppLocalizations.of(context)!.warHistoryNoFavoritesMsg,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecordList extends StatelessWidget {
  final List records;
  final Function(dynamic) onTap;
  final Function(dynamic) onToggleFavorite;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  const _RecordList({
    required this.records,
    required this.onTap,
    required this.onToggleFavorite,
    required this.emptyMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_edu_outlined, color: AppColors.textMuted, size: 64),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.goldAccent,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final record = records[index];
          return HistoryListTile(
            record: record,
            onTap: () => onTap(record),
            onToggleFavorite: () => onToggleFavorite(record),
          );
        },
      ),
    );
  }
}
