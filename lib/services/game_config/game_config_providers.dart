import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/game_config_model.dart';
import '../../features/auth/auth_providers.dart';

/// Streams the game config document from Firestore.
/// Falls back to defaults if the document doesn't exist or on error.
final gameConfigStreamProvider = StreamProvider<GameConfigModel>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.firestoreSystemConfig)
      .doc(AppConstants.firestoreGameConfig)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) {
      return GameConfigModel.defaults();
    }
    try {
      return GameConfigModel.fromJson(snapshot.data()!);
    } catch (e) {
      return GameConfigModel.defaults();
    }
  });
});

/// Synchronous provider that returns the latest game config.
/// Falls back to RC-based config, then defaults.
final gameConfigProvider = Provider<GameConfigModel>((ref) {
  final streamValue = ref.watch(gameConfigStreamProvider);
  return streamValue.maybeWhen(
    data: (config) => config,
    orElse: () {
      // Fallback to defaults while Firestore stream is loading/erroring
      return GameConfigModel.defaults();
    },
  );
});

/// Whether the current user is an admin (in dev_uids list).
final isAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final uid = authState.valueOrNull?.uid;
  if (uid == null) return false;
  final config = ref.watch(gameConfigProvider);
  return config.devUids.contains(uid);
});
