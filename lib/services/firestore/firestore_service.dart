import '../../models/user_model.dart';
import '../../models/pvp_match_model.dart';

abstract class FirestoreService {
  /// Get user data from Firestore.
  Future<UserModel?> getUserData(String uid);

  /// Create a new user document.
  Future<void> createUser(UserModel user);

  /// Update user data.
  Future<void> updateUser(String uid, Map<String, dynamic> data);

  /// Update ticket count by delta (positive or negative).
  Future<void> updateTickets(String uid, int delta);

  /// Create a new PvP match.
  Future<void> createPvpMatch(PvpMatchModel match);

  /// Get active PvP matches for a user.
  Future<List<PvpMatchModel>> getActivePvpMatches(String uid);

  /// Submit a strategy for a PvP match.
  Future<void> submitPvpStrategy(String matchId, String uid, String strategy);

  /// Save the result of a resolved PvP match.
  Future<void> savePvpResult(String matchId, Map<String, dynamic> result);

  /// Stream of a specific PvP match (for real-time updates).
  Stream<PvpMatchModel?> watchPvpMatch(String matchId);

  /// Find a waiting match to join, or null if none available.
  Future<PvpMatchModel?> findWaitingMatch(String uid);
}
