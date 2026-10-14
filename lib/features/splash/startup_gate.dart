import 'dart:math';

/// Why the app stays on the splash screen instead of starting. Remote Config's
/// maintenance_mode and min_app_version existed but nothing read them, so the
/// game could not be closed or an update forced after release (02 C).
enum StartupBlock { maintenance, updateRequired }

/// The block for these Remote Config values, or null to start normally.
/// Maintenance comes first: while the game is closed, an update doesn't help.
StartupBlock? startupBlockFor({
  required bool maintenanceMode,
  required String minAppVersion,
  required String appVersion,
}) {
  if (maintenanceMode) return StartupBlock.maintenance;
  if (isVersionBelow(appVersion, minAppVersion)) return StartupBlock.updateRequired;
  return null;
}

/// True if [version] is lower than [minimum], comparing the dotted numbers
/// ("1.2.10" is above "1.2.9"; a "+build" part is ignored). An empty or
/// unreadable minimum blocks nothing.
bool isVersionBelow(String version, String minimum) {
  final min = _numbers(minimum);
  if (min == null) return false;
  final current = _numbers(version) ?? const [0];
  for (var i = 0; i < max(current.length, min.length); i++) {
    final a = i < current.length ? current[i] : 0;
    final b = i < min.length ? min[i] : 0;
    if (a != b) return a < b;
  }
  return false;
}

List<int>? _numbers(String version) {
  final core = version.trim().split('+').first;
  if (core.isEmpty) return null;
  final parts = core.split('.').map(int.tryParse).toList();
  if (parts.any((p) => p == null || p < 0)) return null;
  return parts.cast<int>();
}
