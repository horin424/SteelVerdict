import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_text_styles.dart';

class ShareToXButton extends StatefulWidget {
  final String text;
  final XFile? imageFile;
  final VoidCallback? onShared;

  const ShareToXButton({
    super.key,
    required this.text,
    this.imageFile,
    this.onShared,
  });

  @override
  State<ShareToXButton> createState() => _ShareToXButtonState();
}

class _ShareToXButtonState extends State<ShareToXButton> {
  bool _isSharing = false;

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      final shareText = '${widget.text}\n\n#StrategyWar #WarChronicle';

      if (widget.imageFile != null) {
        await Share.shareXFiles(
          [widget.imageFile!],
          text: shareText,
        );
      } else {
        await Share.share(shareText);
      }

      widget.onShared?.call();
    } catch (e) {
      debugPrint('Share error: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isSharing ? null : _share,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: _isSharing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.share, size: 18),
      label: Text(
        _isSharing ? AppLocalizations.of(context)!.warHistorySharing : AppLocalizations.of(context)!.warHistoryShare,
        style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
      ),
    );
  }
}
