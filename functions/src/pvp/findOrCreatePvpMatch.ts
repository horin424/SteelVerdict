import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid";

interface FindMatchRequest {
  raceName: string;
  raceStats: Record<string, number>;
}

/**
 * findOrCreatePvpMatch — matchmaking function.
 *
 * Priority: match with players who logged in within the past 3 days first.
 * If no waiting match exists, create a new one (player waits).
 * If a waiting match is found (not your own), join it → status becomes "active".
 *
 * Returns the match document.
 */
export const findOrCreatePvpMatch = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = request.auth.uid;
  const data = request.data as FindMatchRequest;

  if (!data.raceName || !data.raceStats) {
    throw new HttpsError("invalid-argument", "raceName and raceStats are required.");
  }

  const db = admin.firestore();
  const matchesRef = db.collection("pvp_matches");

  // Look for a waiting match (not your own, not expired)
  const now = Date.now();
  const waitingQuery = await matchesRef
    .where("status", "==", "waiting")
    .where("playerBUid", "==", "")
    .orderBy("createdAt", "asc")
    .limit(20)
    .get();

  // Filter: not your own match, not expired
  const candidates = waitingQuery.docs.filter((doc) => {
    const d = doc.data();
    return d.playerAUid !== uid && d.expiresAt > now;
  });

  // Prefer recently-active players (logged in within 3 days)
  // The match document doesn't store lastLogin, so we do a quick user fetch
  // for the top few candidates only to keep costs low.
  let bestMatch: admin.firestore.QueryDocumentSnapshot | null = null;
  if (candidates.length > 0) {
    const threeDaysAgo = now - 3 * 24 * 60 * 60 * 1000;
    for (const candidate of candidates.slice(0, 5)) {
      const playerAUid = candidate.data().playerAUid;
      const userSnap = await db.collection("users").doc(playerAUid).get();
      const lastLogin = (userSnap.data()?.lastLoginAt as number) ?? 0;
      if (lastLogin >= threeDaysAgo) {
        bestMatch = candidate;
        break;
      }
    }
    // Fall back to any candidate if no recently-active player found
    if (!bestMatch) bestMatch = candidates[0];
  }

  if (bestMatch) {
    // Join this match
    const matchData = bestMatch.data();
    const expiresAt = now + 24 * 60 * 60 * 1000;
    await bestMatch.ref.update({
      playerBUid: uid,
      playerBRaceName: data.raceName,
      playerBStats: data.raceStats,
      status: "active",
      expiresAt,
    });

    return {
      matchId: matchData.matchId,
      isNewMatch: false,
      opponentUid: matchData.playerAUid,
      opponentRaceName: matchData.playerARaceName,
      opponentStats: matchData.playerAStats,
      expiresAt,
    };
  }

  // No waiting match — create a new one
  const matchId = uuidv4();
  const expiresAt = now + 24 * 60 * 60 * 1000;
  const newMatch = {
    matchId,
    playerAUid: uid,
    playerBUid: "",
    playerARaceName: data.raceName,
    playerBRaceName: "",
    playerAStats: data.raceStats,
    playerBStats: {},
    playerAStrategy: "",
    playerBStrategy: "",
    shortReport: "",
    winner: "",
    status: "waiting",
    createdAt: now,
    expiresAt,
  };

  await matchesRef.doc(matchId).set(newMatch);

  return {
    matchId,
    isNewMatch: true,
    opponentUid: null,
    opponentRaceName: null,
    opponentStats: null,
    expiresAt,
  };
});
