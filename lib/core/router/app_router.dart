import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/account_link_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/race_creation/screens/race_creation_screen.dart';
import '../../features/world_setting/screens/world_setting_selection_screen.dart';
import '../../features/battle_type/screens/battle_type_selection_screen.dart';
import '../../features/scenario_selection/screens/scenario_selection_screen.dart';
import '../../features/game_mode_selection/screens/game_mode_selection_screen.dart';
import '../../features/battle/screens/battle_screen.dart';
import '../../features/battle/screens/battle_result_screen.dart';
import '../../features/game_hub/screens/game_hub_screen.dart';
import '../../features/pvp/screens/pvp_lobby_screen.dart';
import '../../features/pvp/screens/pvp_battle_screen.dart';
import '../../features/war_history/screens/war_history_screen.dart';
import '../../features/war_history/screens/war_history_detail_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/shop/screens/shop_screen.dart';
import '../../features/settings/screens/help_center_screen.dart';
import '../../features/settings/screens/privacy_policy_screen.dart';
import '../../features/admin/screens/admin_panel_screen.dart';
import '../../features/admin/screens/admin_worldview_editor.dart';
import '../../features/admin/screens/admin_scenario_editor.dart';
import '../../features/admin/screens/admin_mode_addons_editor.dart';
import '../../features/admin/screens/admin_costs_editor.dart';
import '../../features/admin/screens/admin_system_config_editor.dart';
import '../../features/auth/auth_providers.dart';
import '../constants/route_names.dart';
import '../l10n/app_localizations.dart';

// Shell scaffold key
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      final location = state.uri.toString();

      // While Firebase auth is still resolving, send everything through
      // the splash screen. This also fixes Android activity-restoration
      // from landing directly on a route like /war-history on fresh launch.
      if (authState.isLoading) {
        return location.startsWith(RouteNames.splash)
            ? null
            : RouteNames.splash;
      }

      final isAuthenticated = authState.valueOrNull != null;
      final hasRace = ref.read(hasRaceProvider);

      // Always allow splash and auth screens
      if (location.startsWith(RouteNames.splash)) return null;
      if (location.startsWith(RouteNames.auth)) return null;
      if (location.startsWith(RouteNames.accountLink)) return null;

      // If not authenticated, go to auth
      if (!isAuthenticated) {
        return RouteNames.auth;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.auth,
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: RouteNames.accountLink,
        name: 'accountLink',
        builder: (context, state) => const AccountLinkScreen(),
      ),
      GoRoute(
        path: RouteNames.raceCreation,
        name: 'raceCreation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final redirectToBattle = extra?['redirectToBattle'] as bool? ?? false;
          return RaceCreationScreen(redirectToBattle: redirectToBattle);
        },
      ),
      GoRoute(
        path: RouteNames.worldSetting,
        name: 'worldSetting',
        builder: (context, state) => const WorldSettingSelectionScreen(),
      ),
      GoRoute(
        path: RouteNames.battleType,
        name: 'battleType',
        builder: (context, state) => const BattleTypeSelectionScreen(),
      ),
      GoRoute(
        path: '${RouteNames.scenarios}/:battleType',
        name: 'scenarios',
        builder: (context, state) {
          final battleType = state.pathParameters['battleType'] ?? 'standard';
          return ScenarioSelectionScreen(battleType: battleType);
        },
      ),
      GoRoute(
        path: '${RouteNames.gameModeSelection}/:scenarioId',
        name: 'gameModeSelection',
        builder: (context, state) {
          final scenarioId = state.pathParameters['scenarioId'] ?? '';
          return GameModeSelectionScreen(scenarioId: scenarioId);
        },
      ),
      GoRoute(
        path: '${RouteNames.battle}/:scenarioId/:gameMode',
        name: 'battle',
        builder: (context, state) {
          final scenarioId = state.pathParameters['scenarioId'] ?? '';
          final gameMode = state.pathParameters['gameMode'] ?? 'normal';
          return BattleScreen(scenarioId: scenarioId, gameMode: gameMode);
        },
      ),
      GoRoute(
        path: RouteNames.battleResult,
        name: 'battleResult',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BattleResultScreen(resultData: extra);
        },
      ),
      GoRoute(
        path: RouteNames.pvpBattle,
        name: 'pvpBattle',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final matchId = extra?['matchId'] as String? ?? '';
          return PvpBattleScreen(matchId: matchId);
        },
      ),
      GoRoute(
        path: RouteNames.warHistoryDetail,
        name: 'warHistoryDetail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final recordId = extra?['recordId'] as String? ?? '';
          return WarHistoryDetailScreen(recordId: recordId);
        },
      ),
      // Top-level full-screen routes (have back button, no bottom nav)
      GoRoute(
        path: RouteNames.warHistory,
        name: 'warHistory',
        builder: (context, state) => const WarHistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.shop,
        name: 'shop',
        builder: (context, state) => const ShopScreen(),
      ),
      GoRoute(
        path: RouteNames.helpCenter,
        name: 'helpCenter',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: RouteNames.privacyPolicy,
        name: 'privacyPolicy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      // Admin panel routes
      GoRoute(
        path: RouteNames.adminPanel,
        name: 'adminPanel',
        builder: (context, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: RouteNames.adminWorldviews,
        name: 'adminWorldviews',
        builder: (context, state) => const AdminWorldviewEditor(),
      ),
      GoRoute(
        path: RouteNames.adminScenarios,
        name: 'adminScenarios',
        builder: (context, state) => const AdminScenarioEditor(),
      ),
      GoRoute(
        path: RouteNames.adminModeAddons,
        name: 'adminModeAddons',
        builder: (context, state) => const AdminModeAddonsEditor(),
      ),
      GoRoute(
        path: RouteNames.adminCosts,
        name: 'adminCosts',
        builder: (context, state) => const AdminCostsEditor(),
      ),
      GoRoute(
        path: RouteNames.adminSystemConfig,
        name: 'adminSystemConfig',
        builder: (context, state) => const AdminSystemConfigEditor(),
      ),
      // Shell route for bottom navigation (Home / Game / Missions / Profile)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _ShellScaffold(state: state, child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.home,
            name: 'home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: RouteNames.gameHub,
            name: 'gameHub',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GameHubScreen()),
          ),
          GoRoute(
            path: RouteNames.pvpLobby,
            name: 'pvpLobby',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PvpLobbyScreen()),
          ),
          GoRoute(
            path: RouteNames.settings,
            name: 'settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
}

class _ShellScaffold extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const _ShellScaffold({required this.child, required this.state});

  int _selectedIndex(String location) {
    if (location.startsWith(RouteNames.home)) return 0;
    if (location.startsWith(RouteNames.gameHub)) return 1;
    if (location.startsWith(RouteNames.pvpLobby)) return 2;
    if (location.startsWith(RouteNames.settings)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = state.uri.toString();
    final index = _selectedIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.deepNavy,
          border: const Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: AppLocalizations.of(context)!.navHome,
                  isSelected: index == 0,
                  onTap: () => context.go(RouteNames.home),
                ),
                _NavItem(
                  icon: Icons.sports_esports_outlined,
                  activeIcon: Icons.sports_esports,
                  label: AppLocalizations.of(context)!.navGame,
                  isSelected: index == 1,
                  onTap: () => context.go(RouteNames.gameHub),
                ),
                _NavItem(
                  icon: Icons.flag_outlined,
                  activeIcon: Icons.flag,
                  label: AppLocalizations.of(context)!.navMissions,
                  isSelected: index == 2,
                  onTap: () => context.go(RouteNames.pvpLobby),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: AppLocalizations.of(context)!.navProfile,
                  isSelected: index == 3,
                  onTap: () => context.go(RouteNames.settings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.orange : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.orange : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
