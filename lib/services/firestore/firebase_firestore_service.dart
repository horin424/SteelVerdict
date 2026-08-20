import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../../models/pvp_match_model.dart';
import '../../core/constants/app_constants.dart';
import 'firestore_service.dart';

class FirebaseFirestoreService implements FirestoreService {
  final FirebaseFirestore _firestore;

  FirebaseFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _users =>
      _firestore.collection(AppConstants.firestoreUsers);
  CollectionReference get _pvpMatches =>
      _firestore.collection(AppConstants.firestorePvpMatches);

  @override
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;
      return UserModel.fromJson({...data, 'uid': uid});
    } catch (e) {
      debugPrint('FirestoreService.getUserData error: $e');
      return null;
    }
  }

  @override
  Future<void> createUser(UserModel user) async {
    try {
      await _users.doc(user.uid).set(user.toJson());
    } catch (e) {
      debugPrint('FirestoreService.createUser error: $e');
    }
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _users.doc(uid).update(data);
    } catch (e) {
      debugPrint('FirestoreService.updateUser error: $e');
    }
  }

  @override
  Future<void> updateTickets(String uid, int delta) async {
    try {
      await _users.doc(uid).update({
        'ticketCount': FieldValue.increment(delta),
      });
    } catch (e) {
      debugPrint('FirestoreService.updateTickets error: $e');
      rethrow;
    }
  }

  @override
  Future<void> createPvpMatch(PvpMatchModel match) async {
    try {
      await _pvpMatches.doc(match.matchId).set(match.toJson());
    } catch (e) {
      debugPrint('FirestoreService.createPvpMatch error: $e');
      rethrow;
    }
  }

  @override
  Future<List<PvpMatchModel>> getActivePvpMatches(String uid) async {
    try {
      final queryA = await _pvpMatches
          .where('playerAUid', isEqualTo: uid)
          .where('status', whereIn: ['waiting', 'active'])
          .get();
      final queryB = await _pvpMatches
          .where('playerBUid', isEqualTo: uid)
          .where('status', whereIn: ['waiting', 'active'])
          .get();
      final matches = <PvpMatchModel>[];
      for (final doc in [...queryA.docs, ...queryB.docs]) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          matches.add(PvpMatchModel.fromJson(data));
        } catch (e) {
          debugPrint('Error parsing PvP match: $e');
        }
      }
      return matches;
    } catch (e) {
      debugPrint('FirestoreService.getActivePvpMatches error: $e');
      return [];
    }
  }

  @override
  Future<void> submitPvpStrategy(
    String matchId,
    String uid,
    String strategy,
  ) async {
    try {
      final doc = await _pvpMatches.doc(matchId).get();
      if (!doc.exists) throw Exception('Match not found');
      final data = doc.data() as Map<String, dynamic>;
      final match = PvpMatchModel.fromJson(data);

      final updateData = <String, dynamic>{};
      if (uid == match.playerAUid) {
        updateData['playerAStrategy'] = strategy;
      } else if (uid == match.playerBUid) {
        updateData['playerBStrategy'] = strategy;
      } else {
        throw Exception('User is not a participant in this match');
      }

      // Check if both have submitted
      final newMatch = match.copyWith(
        playerAStrategy: uid == match.playerAUid ? strategy : match.playerAStrategy,
        playerBStrategy: uid == match.playerBUid ? strategy : match.playerBStrategy,
      );
      if (newMatch.playerAStrategy.isNotEmpty &&
          newMatch.playerBStrategy.isNotEmpty) {
        updateData['status'] = PvpMatchStatus.active.name;
      }

      await _pvpMatches.doc(matchId).update(updateData);
    } catch (e) {
      debugPrint('FirestoreService.submitPvpStrategy error: $e');
      rethrow;
    }
  }

  @override
  Future<void> savePvpResult(String matchId, Map<String, dynamic> result) async {
    try {
      await _pvpMatches.doc(matchId).update({
        ...result,
        'status': PvpMatchStatus.resolved.name,
      });
    } catch (e) {
      debugPrint('FirestoreService.savePvpResult error: $e');
      rethrow;
    }
  }

  @override
  Stream<PvpMatchModel?> watchPvpMatch(String matchId) {
    return _pvpMatches.doc(matchId).snapshots().map((doc) {
      if (!doc.exists) return null;
      try {
        final data = doc.data() as Map<String, dynamic>;
        return PvpMatchModel.fromJson(data);
      } catch (e) {
        return null;
      }
    });
  }

  @override
  Future<PvpMatchModel?> findWaitingMatch(String uid) async {
    try {
      final query = await _pvpMatches
          .where('status', isEqualTo: 'waiting')
          .where('playerBUid', isEqualTo: '')
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      final data = query.docs.first.data() as Map<String, dynamic>;
      final match = PvpMatchModel.fromJson(data);
      // Don't join your own match
      if (match.playerAUid == uid) return null;
      return match;
    } catch (e) {
      debugPrint('FirestoreService.findWaitingMatch error: $e');
      return null;
    }
  }
}
