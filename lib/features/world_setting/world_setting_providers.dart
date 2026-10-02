import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../splash/splash_providers.dart';

/// The worldview the player is currently playing in.
///
/// Lives here rather than in game_mode_providers.dart because auth_providers.dart
/// needs it (a race now belongs to a worldview), and game_mode_providers.dart
/// already imports auth_providers.dart — putting it there would make the import
/// cycle. game_mode_providers.dart re-exports it so existing imports still work.
/// Key the selection is stored under.
const String kSelectedWorldviewSetting = 'selected_worldview';

/// The selected worldview, remembered across launches.
///
/// While this reset to the default on every launch, a player who had built a
/// race in one world reopened the app in a different one, had no race there,
/// and was sent to race creation - from every entry point. That is the
/// "everything leads to race creation" the client reported. Per-world race
/// storage did not cause it; it made an already-unpersisted selection visible,
/// because before that the one global race was found whatever world the app
/// happened to reset to.
class SelectedWorldviewNotifier extends Notifier<String> {
  @override
  String build() {
    // Hive is opened in bootstrap() before runApp, so this read is safe on the
    // provider's first evaluation.
    final saved = ref
        .watch(hiveStorageServiceProvider)
        .getSetting(kSelectedWorldviewSetting);

    // A world deleted from the config since it was chosen leaves a stale key.
    // activeWorldviewProvider already falls back to the default worldview for
    // an unknown key, so that degrades to "no race in this world" rather than
    // an error, and corrects itself as soon as the player picks a world.
    return (saved is String && saved.isNotEmpty)
        ? saved
        : AppConstants.defaultWorldviewKey;
  }

  Future<void> select(String worldviewKey) async {
    if (state == worldviewKey) return;
    state = worldviewKey;
    await ref
        .read(hiveStorageServiceProvider)
        .saveSetting(kSelectedWorldviewSetting, worldviewKey);
  }
}

final selectedWorldviewKeyProvider =
    NotifierProvider<SelectedWorldviewNotifier, String>(
      SelectedWorldviewNotifier.new,
    );
