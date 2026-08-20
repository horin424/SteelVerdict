import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class GeneralStaffOverlay extends StatefulWidget {
  final bool isVisible;
  final String? currentPhase;
  final VoidCallback? onWatchAd;
  final VoidCallback? onSkip;

  const GeneralStaffOverlay({
    super.key,
    required this.isVisible,
    this.currentPhase,
    this.onWatchAd,
    this.onSkip,
  });

  @override
  State<GeneralStaffOverlay> createState() => _GeneralStaffOverlayState();
}

class _GeneralStaffOverlayState extends State<GeneralStaffOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _phaseIndex = 0;

  List<String> _phases(AppLocalizations l10n) => [
    l10n.generalStaffMsg1,
    l10n.generalStaffMsg2,
    l10n.generalStaffMsg3,
    l10n.generalStaffMsg4,
    l10n.generalStaffMsg5,
    l10n.generalStaffMsg6,
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);

    if (widget.isVisible) {
      _fadeController.forward();
      _startPhaseTimer();
    }
  }

  @override
  void didUpdateWidget(GeneralStaffOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _fadeController.forward();
      _startPhaseTimer();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _fadeController.reverse();
    }
  }

  void _startPhaseTimer() async {
    while (mounted && widget.isVisible) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _phaseIndex = (_phaseIndex + 1) % 6;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!widget.isVisible) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Backdrop
          Container(
            color: AppColors.darkBackground.withValues(alpha: 0.92),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated badge
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Opacity(
                    opacity: _pulseAnimation.value,
                    child: child,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.navyMid,
                      border: Border.all(color: AppColors.goldAccent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldAccent.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.military_tech,
                      size: 40,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.generalStaffTitle,
                  style: AppTextStyles.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.generalStaffAnalyzing,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 24),
                // Phase text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    widget.currentPhase ?? _phases(l10n)[_phaseIndex],
                    key: ValueKey(widget.currentPhase ?? _phaseIndex),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.goldAccent,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                // Watch Ad / Skip buttons (tabletop mode)
                if (widget.onWatchAd != null || widget.onSkip != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.onWatchAd != null)
                        TextButton.icon(
                          onPressed: widget.onWatchAd,
                          icon: const Icon(Icons.play_circle_outline, size: 16),
                          label: Text(
                            AppLocalizations.of(context)!.watchAdFree,
                            style: AppTextStyles.labelSmall,
                          ),
                        ),
                      if (widget.onWatchAd != null && widget.onSkip != null)
                        const SizedBox(width: 8),
                      if (widget.onSkip != null)
                        TextButton.icon(
                          onPressed: widget.onSkip,
                          icon: const Icon(Icons.skip_next_outlined, size: 16),
                          label: Text(
                            AppLocalizations.of(context)!.skipAdCost,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                // Loading bar
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldAccent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
