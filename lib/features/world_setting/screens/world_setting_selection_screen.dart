import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/game_mode_selection/game_mode_providers.dart';
import '../../../features/settings/settings_providers.dart';
import '../../../models/worldview_model.dart';
import '../../../services/game_config/game_config_providers.dart';

class WorldSettingSelectionScreen extends ConsumerWidget {
  const WorldSettingSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider).languageCode;
    final gameConfig = ref.watch(gameConfigProvider);

    final worldviews = gameConfig.worldviews.isNotEmpty
        ? gameConfig.worldviews
        : {
            WorldviewModel.defaultWorldview().worldviewKey:
                WorldviewModel.defaultWorldview(),
          };

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.steelDark,
        title: Text(
          l10n.worldSettingChoose,
          style: AppTextStyles.headlineMedium,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.borderGold,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              l10n.worldSettingSubtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: worldviews.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = worldviews.entries.elementAt(index);
                return _WorldSettingCard(
                  worldview: entry.value,
                  locale: locale,
                  onTap: () {
                    ref.read(selectedWorldviewKeyProvider.notifier).state =
                        entry.key;
                    context.push(RouteNames.battleType);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldSettingCard extends StatelessWidget {
  final WorldviewModel worldview;
  final String locale;
  final VoidCallback onTap;

  const _WorldSettingCard({
    required this.worldview,
    required this.locale,
    required this.onTap,
  });

  /// Returns (gradientColors, glowColor, accentColor) for a given worldviewKey.
  static _WorldColors _colorsFor(String key) {
    switch (key) {
      case '1830_fantasy':
        return _WorldColors(
          gradient: [Color(0xFF0C1A2E), Color(0xFF152640), Color(0xFF1E3A5F)],
          glow: Color(0xFF2C5FA8),
          accent: Color(0xFF4A90D9),
        );
      case 'naval_warfare':
        return _WorldColors(
          gradient: [Color(0xFF051520), Color(0xFF0A2A3A), Color(0xFF0D3D52)],
          glow: Color(0xFF006994),
          accent: Color(0xFF00B4D8),
        );
      case 'aerial_warfare':
        return _WorldColors(
          gradient: [Color(0xFF0A0E1A), Color(0xFF101830), Color(0xFF1A2850)],
          glow: Color(0xFF48CAE4),
          accent: Color(0xFF90E0EF),
        );
      case 'ancient_fantasy':
        return _WorldColors(
          gradient: [Color(0xFF1A0A00), Color(0xFF2E1200), Color(0xFF4A1E00)],
          glow: Color(0xFFB85C00),
          accent: Color(0xFFE87A20),
        );
      case 'dark_magic':
        return _WorldColors(
          gradient: [Color(0xFF110A1F), Color(0xFF1E1038), Color(0xFF2D1850)],
          glow: Color(0xFF6A0DAD),
          accent: Color(0xFF9B59B6),
        );
      default:
        // Deterministic color from hash for unknown worlds
        final hash = key.hashCode.abs();
        final palettes = [
          _WorldColors(
            gradient: [Color(0xFF0C1A2E), Color(0xFF152640), Color(0xFF1E3A5F)],
            glow: Color(0xFF2C5FA8),
            accent: Color(0xFF4A90D9),
          ),
          _WorldColors(
            gradient: [Color(0xFF1A0A00), Color(0xFF2E1200), Color(0xFF4A1E00)],
            glow: Color(0xFFB85C00),
            accent: Color(0xFFE87A20),
          ),
          _WorldColors(
            gradient: [Color(0xFF051520), Color(0xFF0A2A3A), Color(0xFF0D3D52)],
            glow: Color(0xFF006994),
            accent: Color(0xFF00B4D8),
          ),
          _WorldColors(
            gradient: [Color(0xFF110A1F), Color(0xFF1E1038), Color(0xFF2D1850)],
            glow: Color(0xFF6A0DAD),
            accent: Color(0xFF9B59B6),
          ),
        ];
        return palettes[hash % palettes.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colorsFor(worldview.worldviewKey);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: c.gradient,
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.goldDim.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: c.glow.withValues(alpha: 0.28),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accent top stripe with world color
            Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    c.accent.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: c.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      Icons.public,
                      color: c.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worldview.localizedTitle(locale),
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          worldview.localizedDescription(locale),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Stat chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: worldview.stats.map((stat) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: c.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: c.accent.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                worldview.getStatDescription(stat, locale),
                                style: TextStyle(
                                  color: c.accent.withValues(alpha: 0.9),
                                  fontSize: 9,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldColors {
  final List<Color> gradient;
  final Color glow;
  final Color accent;

  const _WorldColors({
    required this.gradient,
    required this.glow,
    required this.accent,
  });
}
