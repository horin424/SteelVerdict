import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/route_names.dart';
import '../../core/l10n/app_localizations.dart';
import '../../features/auth/auth_providers.dart';
import 'splash_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _gateInAnim;
  late Animation<double> _gateOutAnim;
  late Animation<double> _flashAnim;
  late Animation<double> _logoFadeAnim;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );

    _gateInAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.42, curve: Curves.easeInCubic),
    );

    _gateOutAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.52, 0.82, curve: Curves.easeIn),
    );

    _flashAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.5),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 0.0),
        weight: 75,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.54),
    ));

    _logoFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.88, curve: Curves.easeOut),
    );

    _loadingAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 1.0, curve: Curves.easeInOut),
    );

    _controller.forward();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      await ref.read(initializationProvider.future);
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    await _navigate();
  }

  Future<void> _navigate() async {
    final user = await ref.read(authStateChangesProvider.future);
    if (!mounted) return;
    if (user != null) {
      context.go(RouteNames.home);
    } else {
      context.go(RouteNames.auth);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final gateProgress = _gateInAnim.value; // 0→1: gates close
          final exitProgress = _gateOutAnim.value; // 0→1: gates exit down

          // Left gate: slides from -halfWidth to 0 (x-axis, closing)
          final leftGateX = -(screenSize.width / 2) * (1.0 - gateProgress);
          // Right gate: slides from +halfWidth to 0 (x-axis, closing)
          final rightGateX = (screenSize.width / 2) * (1.0 - gateProgress);
          // Both gates: slide down off screen on exit
          final gateY = screenSize.height * exitProgress;

          return Stack(
            children: [
              // Background gradient (always visible beneath gates)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF04080F),
                      Color(0xFF0D1B2A),
                      Color(0xFF1A1A2E),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Ambient glow top-right
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orange.withValues(alpha: 0.07),
                  ),
                ),
              ),
              // Ambient glow bottom-left
              Positioned(
                bottom: -80,
                left: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.purple.withValues(alpha: 0.06),
                  ),
                ),
              ),

              // Logo content — fades in after gates open
              Opacity(
                opacity: _logoFadeAnim.value,
                child: SafeArea(child: _buildLogoContent(context)),
              ),

              // Left steel gate panel
              Positioned(
                top: 0,
                left: 0,
                width: screenSize.width / 2,
                height: screenSize.height,
                child: Transform.translate(
                  offset: Offset(leftGateX, gateY),
                  child: const _SteelGatePanel(isLeft: true),
                ),
              ),

              // Right steel gate panel
              Positioned(
                top: 0,
                right: 0,
                width: screenSize.width / 2,
                height: screenSize.height,
                child: Transform.translate(
                  offset: Offset(rightGateX, gateY),
                  child: const _SteelGatePanel(isLeft: false),
                ),
              ),

              // Impact flash when gates meet
              if (_flashAnim.value > 0.01)
                Opacity(
                  opacity: _flashAnim.value,
                  child: Container(
                    color: AppColors.orange.withValues(alpha: 0.55),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Shield icon with glow
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.orange.withValues(alpha: 0.3),
                  AppColors.deepNavy,
                ],
              ),
              border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.shield,
              size: 72,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(height: 36),

          // Title
          Text(
            l10n.splashTitleLine1,
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 36,
              color: AppColors.orange,
              letterSpacing: 6,
            ),
          ),
          Text(
            l10n.splashTitleLine2,
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 36,
              color: AppColors.goldAccent,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.splashTagline,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),

          // Loading bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _loadingAnimation.value,
                    backgroundColor: AppColors.navyMid,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.orange,
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.loading,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
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

class _SteelGatePanel extends StatelessWidget {
  final bool isLeft;

  const _SteelGatePanel({required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLeft
              ? [
                  const Color(0xFF141414),
                  const Color(0xFF2A2A2A),
                  const Color(0xFF222222),
                ]
              : [
                  const Color(0xFF222222),
                  const Color(0xFF2A2A2A),
                  const Color(0xFF141414),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          // Horizontal steel plate lines
          for (int i = 0; i < 24; i++)
            Positioned(
              top: i * 38.0,
              left: 0,
              right: 0,
              height: 1,
              child: Container(
                color: Colors.white.withValues(alpha: 0.035),
              ),
            ),

          // Vertical rivet strip at inner edge
          Positioned(
            top: 0,
            bottom: 0,
            right: isLeft ? 0 : null,
            left: isLeft ? null : 0,
            width: 18,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLeft
                      ? [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                        ]
                      : [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // Orange glow at inner meeting edge
          Positioned(
            top: 0,
            bottom: 0,
            right: isLeft ? 0 : null,
            left: isLeft ? null : 0,
            width: 2,
            child: Container(
              color: AppColors.orange.withValues(alpha: 0.75),
            ),
          ),

          // Rivets along inner edge
          ...List.generate(7, (i) {
            return Positioned(
              top: 40.0 + i * 70,
              right: isLeft ? 5 : null,
              left: isLeft ? null : 5,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3C3C3C),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          }),

          // Outer edge shadow
          Positioned(
            top: 0,
            bottom: 0,
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            width: 6,
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
