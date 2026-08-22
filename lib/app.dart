import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/l10n/app_localizations.dart';
import 'core/router/router_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/settings_providers.dart';

/// The one ScaffoldMessenger for the whole app.
///
/// ErrorSnackbar used to call ScaffoldMessenger.of(context), which finds the
/// *nearest* messenger - a route-local one. When that route was replaced while
/// its snackbar was still on screen, the snackbar was left painted with a dead
/// controller: it ignored its own 4-second timeout and its Dismiss action was a
/// no-op. Seen on device as "Authentication failed." pinned over the home
/// screen after a later, successful sign-in.
///
/// Routing every snackbar through one app-level messenger means it always
/// outlives the screen that raised it.
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: appScaffoldMessengerKey,
      title: 'Steel Verdict',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ja'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
