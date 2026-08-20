import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isVisible;
  final String? message;
  final List<String>? flavorTexts;

  const LoadingOverlay({
    super.key,
    required this.isVisible,
    this.message,
    this.flavorTexts,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Stack(
      children: [
        // Backdrop
        ModalBarrier(
          dismissible: false,
          color: AppColors.darkBackground.withValues(alpha: 0.85),
        ),
        // Content
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            decoration: BoxDecoration(
              color: AppColors.navyMid,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGold, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldAccent.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.goldAccent,
                    ),
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    message!,
                    style: AppTextStyles.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (flavorTexts != null && flavorTexts!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _FlavorTextCycler(texts: flavorTexts!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FlavorTextCycler extends StatefulWidget {
  final List<String> texts;

  const _FlavorTextCycler({required this.texts});

  @override
  State<_FlavorTextCycler> createState() => _FlavorTextCyclerState();
}

class _FlavorTextCyclerState extends State<_FlavorTextCycler> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startCycling();
  }

  void _startCycling() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.texts.length;
        });
        _startCycling();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Text(
        widget.texts[_currentIndex],
        key: ValueKey(_currentIndex),
        style: AppTextStyles.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Widget-level wrapper that positions a LoadingOverlay on top of its child.
class LoadingOverlayWrapper extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlayWrapper({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          LoadingOverlay(
            isVisible: isLoading,
            message: message,
          ),
      ],
    );
  }
}
