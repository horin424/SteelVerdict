import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/splash/splash_providers.dart';

class SavedStrategiesPicker extends ConsumerWidget {
  final ValueChanged<String> onSelected;

  const SavedStrategiesPicker({super.key, required this.onSelected});

  static Future<void> show(BuildContext context, {required ValueChanged<String> onSelected}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyMid,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.borderColor),
      ),
      builder: (ctx) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (_, controller) => SavedStrategiesPicker(onSelected: onSelected),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageService = ref.read(hiveStorageServiceProvider);
    final strategies = storageService.getStrategies();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(AppLocalizations.of(context)!.savedStrategiesTitle, style: AppTextStyles.headlineMedium),
              const Spacer(),
              Text(AppLocalizations.of(context)!.savedStrategiesCount(strategies.length), style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        const Divider(color: AppColors.divider),
        if (strategies.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_edu_outlined, color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.savedStrategiesEmpty, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: strategies.length,
              itemBuilder: (context, index) {
                final entry = strategies[index];
                return ListTile(
                  title: Text(entry.key, style: AppTextStyles.labelLarge),
                  subtitle: Text(
                    entry.value.length > 100
                        ? '${entry.value.substring(0, 100)}...'
                        : entry.value,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.goldAccent),
                  onTap: () {
                    onSelected(entry.value);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
