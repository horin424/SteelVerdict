import '../../models/game_config_model.dart';

abstract class RemoteConfigService {
  /// Fetch and activate the latest Remote Config values.
  Future<void> fetchAndActivate();

  /// Get the full game config from Remote Config.
  GameConfigModel getGameConfig();

  /// Get an ad unit ID for the given slot ('rewarded' or 'interstitial').
  String getAdUnitId(String slot);

  /// Get the ticket cost for a specific game mode.
  int getTicketCost(String gameMode);

  /// Check if maintenance mode is enabled.
  bool get isMaintenanceMode;
}
