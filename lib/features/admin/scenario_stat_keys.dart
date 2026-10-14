import '../../core/constants/app_constants.dart';
import '../../models/worldview_model.dart';

/// The stat names from before worlds had their own. Used only when neither the
/// scenario's world nor the default world defines any.
const legacyStatKeys = ['strength', 'intellect', 'skill', 'magic', 'art', 'life'];

/// The stat names a new or empty scenario gets: its world's own, else the
/// default world's, else the legacy list. The same rule as the PC admin
/// (admin-web/js/editors/scenarios.js, defaultStatKeys). This editor always
/// used the legacy list, so its enemies didn't have the world's stats (02 C).
List<String> defaultStatKeys(Map<String, WorldviewModel> worlds, String worldKey) {
  final own = worlds[worldKey]?.stats ?? const <String>[];
  if (own.isNotEmpty) return own;
  final fallback = worlds[AppConstants.defaultWorldviewKey]?.stats ?? const <String>[];
  return fallback.isNotEmpty ? fallback : legacyStatKeys;
}

/// [keys] in the world's stat order, then any others alphabetically.
List<String> orderedStatKeys(Iterable<String> keys, List<String> worldOrder) {
  final all = keys.toList();
  final others = all.where((k) => !worldOrder.contains(k)).toList()..sort();
  return [...worldOrder.where(all.contains), ...others];
}
