import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/error_snackbar.dart';

/// Reporting AI output (the 「報告」 button on the battle result and war
/// history screens). Google Play's AI-Generated Content policy asks for a way
/// to report offensive AI output without leaving the app. The battle reports
/// and chronicles live only on the phone, so the report carries the text; the
/// server (reportAiContent) saves it for the PC admin's 「報告」 page, at most
/// 20 a day per account.

/// One AI text on the screen that the player can report.
class AiReportTarget {
  /// "battle" (the battle report) or "chronicle" (the war chronicle), as the server expects.
  final String kind;
  final String text;

  const AiReportTarget({required this.kind, required this.text});
}

/// The reasons, named as the server expects them.
enum AiReportReason { offensive, violence, sexual, other }

/// How sending a report went.
enum AiReportResult { sent, limit, failed }

typedef AiReportSender = Future<AiReportResult> Function(Map<String, dynamic> payload);

/// Sends the report to reportAiContent.
Future<AiReportResult> sendAiReportToServer(Map<String, dynamic> payload) async {
  try {
    await FirebaseFunctions.instance.httpsCallable('reportAiContent').call(payload);
    return AiReportResult.sent;
  } on FirebaseFunctionsException catch (e) {
    return e.code == 'resource-exhausted' ? AiReportResult.limit : AiReportResult.failed;
  } catch (_) {
    return AiReportResult.failed;
  }
}

/// Opens the report sheet for [targets] (the first is chosen at the start)
/// and, once a report is sent, says so.
Future<void> showAiReportSheet(
  BuildContext context, {
  required List<AiReportTarget> targets,
  String strategy = '',
  String gameMode = '',
  String scenarioId = '',
  String worldviewKey = '',
  AiReportSender send = sendAiReportToServer,
}) async {
  final usable = targets.where((t) => t.text.trim().isNotEmpty).toList();
  if (usable.isEmpty) return;
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.navyMid,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => AiReportSheet(
      targets: usable,
      strategy: strategy,
      gameMode: gameMode,
      scenarioId: scenarioId,
      worldviewKey: worldviewKey,
      send: send,
    ),
  );
  if (sent == true && context.mounted) {
    ErrorSnackbar.showSuccess(context, AppLocalizations.of(context)!.aiReportSent);
  }
}

class AiReportSheet extends StatefulWidget {
  final List<AiReportTarget> targets;
  final String strategy;
  final String gameMode;
  final String scenarioId;
  final String worldviewKey;
  final AiReportSender send;

  const AiReportSheet({
    super.key,
    required this.targets,
    required this.send,
    this.strategy = '',
    this.gameMode = '',
    this.scenarioId = '',
    this.worldviewKey = '',
  });

  @override
  State<AiReportSheet> createState() => _AiReportSheetState();
}

class _AiReportSheetState extends State<AiReportSheet> {
  int _target = 0;
  AiReportReason? _reason;
  final _comment = TextEditingController();
  bool _sending = false;
  AiReportResult? _problem;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    setState(() {
      _sending = true;
      _problem = null;
    });
    final target = widget.targets[_target];
    final result = await widget.send({
      'kind': target.kind,
      'reason': reason.name,
      'aiText': target.text,
      'strategy': widget.strategy,
      'comment': _comment.text.trim(),
      'gameMode': widget.gameMode,
      'scenarioId': widget.scenarioId,
      'worldviewKey': widget.worldviewKey,
      'appVersion': AppConstants.appVersion,
    });
    if (!mounted) return;
    if (result == AiReportResult.sent) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _sending = false;
      _problem = result;
    });
  }

  String _targetLabel(AppLocalizations l10n, String kind) =>
      kind == 'chronicle' ? l10n.aiReportTargetChronicle : l10n.aiReportTargetBattle;

  String _reasonLabel(AppLocalizations l10n, AiReportReason reason) {
    switch (reason) {
      case AiReportReason.offensive:
        return l10n.aiReportReasonOffensive;
      case AiReportReason.violence:
        return l10n.aiReportReasonViolence;
      case AiReportReason.sexual:
        return l10n.aiReportReasonSexual;
      case AiReportReason.other:
        return l10n.aiReportReasonOther;
    }
  }

  Widget _chip(String label, bool selected, VoidCallback? onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: onTap == null ? null : (_) => onTap(),
        selectedColor: AppColors.goldAccent.withValues(alpha: 0.25),
        side: BorderSide(color: selected ? AppColors.goldAccent : AppColors.borderColor),
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: selected ? AppColors.goldAccent : AppColors.textPrimary,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final problem = _problem;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.aiReportTitle, style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(l10n.aiReportExplain, style: AppTextStyles.bodySmall),
            if (widget.targets.length > 1) ...[
              const SizedBox(height: 16),
              Text(l10n.aiReportWhat, style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < widget.targets.length; i++)
                    _chip(
                      _targetLabel(l10n, widget.targets[i].kind),
                      i == _target,
                      _sending ? null : () => setState(() => _target = i),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(l10n.aiReportWhy, style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final reason in AiReportReason.values)
                  _chip(
                    _reasonLabel(l10n, reason),
                    reason == _reason,
                    _sending ? null : () => setState(() => _reason = reason),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _comment,
              enabled: !_sending,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(hintText: l10n.aiReportCommentHint),
            ),
            if (problem != null) ...[
              const SizedBox(height: 8),
              Text(
                problem == AiReportResult.limit ? l10n.aiReportLimit : l10n.aiReportFailed,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.warRedBright),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _sending ? null : () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _reason == null || _sending ? null : _submit,
                  child: _sending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.aiReportSend),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
