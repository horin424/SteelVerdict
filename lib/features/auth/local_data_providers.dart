import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../splash/splash_providers.dart';
import '../war_history/war_history_providers.dart';
import 'auth_providers.dart';

/// Hands the phone's game data saved before per-account keys to the first
/// account that signs in, then has the screens read it again.
///
/// Bootstrap and HiveStorageService.initialize() already do this for the
/// account that is signed in at start-up, so this matters only on a phone where
/// nobody was signed in when the update arrived. Watched by App.
final localDataBootstrapProvider = Provider<void>((ref) {
  ref.listen<String?>(localDataUidProvider, (previous, uid) {
    if (uid == null || uid == previous) return;
    unawaited(() async {
      final moved = await ref.read(hiveStorageServiceProvider).adoptUnownedData(uid);
      if (moved > 0) {
        ref.invalidate(currentRaceProvider);
        ref.invalidate(battleRecordsProvider);
        ref.invalidate(warHistoriesProvider);
      }
    }());
  }, fireImmediately: true);
});
