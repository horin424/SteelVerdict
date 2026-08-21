import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';

/// The worldview the player is currently playing in.
///
/// Lives here rather than in game_mode_providers.dart because auth_providers.dart
/// needs it (a race now belongs to a worldview), and game_mode_providers.dart
/// already imports auth_providers.dart — putting it there would make the import
/// cycle. game_mode_providers.dart re-exports it so existing imports still work.
final selectedWorldviewKeyProvider = StateProvider<String>(
  (ref) => AppConstants.defaultWorldviewKey,
);
