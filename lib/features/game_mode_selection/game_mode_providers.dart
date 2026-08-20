import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../services/battle_api/battle_api_service.dart';
import '../../models/worldview_model.dart';
import '../../services/game_config/game_config_providers.dart';
import '../auth/auth_providers.dart';

// Selected game mode
final selectedGameModeProvider = StateProvider<String>((ref) => 'normal');

// Selected AI model
final selectedModelProvider = StateProvider<ModelChoice>(
  (ref) => ModelChoice.gemini,
);

// Selected worldview key
final selectedWorldviewKeyProvider = StateProvider<String>(
  (ref) => AppConstants.defaultWorldviewKey,
);

// Available worldviews from Firestore game config
final availableWorldviewsProvider = Provider<Map<String, WorldviewModel>>((
  ref,
) {
  final config = ref.watch(gameConfigProvider);
  return config.worldviews;
});

// Mode availability (based on subscription)
class ModeAvailability {
  final bool normalAvailable;
  final bool tabletopAvailable;
  final bool epicAvailable;
  final bool bossAvailable;
  final bool practiceAvailable;
  final bool historyPuzzleAvailable;

  const ModeAvailability({
    this.normalAvailable = true,
    this.tabletopAvailable = true,
    this.epicAvailable = false,
    this.bossAvailable = false,
    this.practiceAvailable = true,
    this.historyPuzzleAvailable = true,
  });
}

final modeAvailabilityProvider = FutureProvider<ModeAvailability>((ref) async {
  final userModel = await ref.watch(currentUserModelProvider.future);
  if (userModel == null) return const ModeAvailability();

  final isEpicEnabled = userModel.subscriptionTier.name != 'free';
  final isBossEnabled = userModel.isBossEnabled;

  return ModeAvailability(
    normalAvailable: true,
    tabletopAvailable: true,
    epicAvailable: isEpicEnabled,
    bossAvailable: isBossEnabled,
    practiceAvailable: true,
    historyPuzzleAvailable: true,
  );
});

// Ticket costs from Firestore game config
final ticketCostsProvider = Provider<Map<String, int>>((ref) {
  final config = ref.watch(gameConfigProvider);
  return config.ticketCosts;
});

// Effective ticket cost considering model choice
final effectiveTicketCostProvider = Provider<int>((ref) {
  final mode = ref.watch(selectedGameModeProvider);
  final model = ref.watch(selectedModelProvider);
  final costs = ref.watch(ticketCostsProvider);

  // Practice is always free
  if (mode == 'practice') return 0;

  // Claude has its own cost
  if (model == ModelChoice.claude) {
    return costs['claude'] ?? 3;
  }

  // Otherwise use mode-based cost
  return costs[mode] ?? 1;
});
