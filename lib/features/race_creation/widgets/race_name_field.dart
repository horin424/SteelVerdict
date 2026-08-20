import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/content_filter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';

class RaceNameField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const RaceNameField({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<RaceNameField> createState() => _RaceNameFieldState();
}

class _RaceNameFieldState extends State<RaceNameField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.raceCreationNameLabel, style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          style: AppTextStyles.bodyMedium,
          maxLength: AppConstants.maxRaceNameLength,
          decoration: InputDecoration(
            hintText: l10n.raceNamePlaceholder,
            counterStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.military_tech_outlined, color: AppColors.textMuted),
          ),
          onChanged: (value) {
            final filtered = ContentFilter.filterText(value);
            if (filtered != value) {
              _controller.value = _controller.value.copyWith(
                text: filtered,
                selection: TextSelection.collapsed(offset: filtered.length),
              );
            }
            widget.onChanged(filtered);
          },
          validator: (v) => Validators.validateRaceName(v, l10n: l10n),
        ),
      ],
    );
  }
}
