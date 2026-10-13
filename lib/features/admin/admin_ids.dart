import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';

/// Whether [config], the game config document, already has [id] under
/// [section] ('worldviews' or 'scenarios').
bool configHasId(Map<String, dynamic>? config, String section, String id) {
  final entries = config?[section];
  return entries is Map && entries.containsKey(id);
}

/// Whether [id] is already taken under [section].
///
/// Adding a world or scenario merged a blank entry over any existing one with
/// the same ID: its title became the ID, and its prompts and descriptions were
/// emptied (B23). The add dialogs now refuse a taken ID. The document is read
/// fresh, because the cached config may be out of date.
Future<bool> gameConfigHasId(String section, String id) async {
  final doc = await FirebaseFirestore.instance
      .collection(AppConstants.firestoreSystemConfig)
      .doc(AppConstants.firestoreGameConfig)
      .get();
  return configHasId(doc.data(), section, id);
}
