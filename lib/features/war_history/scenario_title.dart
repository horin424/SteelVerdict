import '../../models/game_config_model.dart';

/// The name to show for a battle record's scenario.
///
/// A record stores a title at save time, which freezes it in whatever language
/// was current then — and older records stored the raw scenario id, so war
/// history rows read `SCENARIO_001` in both languages.
///
/// Resolving against the live config first means the row follows the app's
/// language and picks up any later rename. The stored title is the fallback for
/// a scenario that has since been deleted, and the id is the last resort so a
/// row is never blank.
String scenarioDisplayTitle({
  required GameConfigModel config,
  required String scenarioId,
  required String storedTitle,
  required String languageCode,
}) {
  final scenario = config.scenarios[scenarioId];
  if (scenario != null) {
    final live = scenario.localizedTitle(languageCode);
    if (live.isNotEmpty) return live;
  }
  // Older records stored the id here, so reject a stored title that is just the
  // id — otherwise the fallback reproduces the bug it exists to hide.
  if (storedTitle.isNotEmpty && storedTitle != scenarioId) return storedTitle;
  return scenarioId;
}
