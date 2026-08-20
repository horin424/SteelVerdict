import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_providers.dart';
import 'app_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = createRouter(ref);

  // Re-run redirect whenever auth state or race state changes.
  // Without this, router redirect only fires on explicit navigation events.
  ref.listen(authStateChangesProvider, (prev, next) => router.refresh());
  ref.listen(hasRaceProvider, (prev, next) => router.refresh());

  return router;
});
