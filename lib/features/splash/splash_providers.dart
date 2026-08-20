import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/remote_config/remote_config_service.dart';
import '../../services/remote_config/firebase_remote_config_service.dart';
import '../../services/local_storage/hive_storage_service.dart';
import '../../services/local_storage/local_storage_service.dart';

// Service providers
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return FirebaseRemoteConfigService();
});

final hiveStorageServiceProvider = Provider<HiveStorageService>((ref) {
  return HiveStorageService();
});

// Reuses the same initialized instance as hiveStorageServiceProvider
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return ref.watch(hiveStorageServiceProvider);
});

/// FutureProvider that runs all startup initialization tasks.
final initializationProvider = FutureProvider<void>((ref) async {
  // Initialize Hive storage
  final hiveService = ref.read(hiveStorageServiceProvider);
  await hiveService.initialize();

  // Fetch Remote Config
  final remoteConfig = ref.read(remoteConfigServiceProvider);
  await remoteConfig.fetchAndActivate();
});
