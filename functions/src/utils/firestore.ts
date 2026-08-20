import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

const db = () => admin.firestore();

// Collection names — must match app_constants.dart
const USERS = "users";
const PVP_MATCHES = "pvp_matches";

// ─── User helpers ────────────────────────────────────────────────────────────

export async function getUser(uid: string) {
  const doc = await db().collection(USERS).doc(uid).get();
  if (!doc.exists) throw new HttpsError("not-found", "User document not found.");
  return doc.data() as FirestoreUser;
}

export async function createUserDoc(uid: string, displayName: string) {
  const now = Date.now();
  const user: FirestoreUser = {
    uid,
    displayName: displayName || "Anonymous Commander",
    ticketCount: 3, // Starting tickets
    subscriptionTier: "free",
    lastLoginAt: now,
    createdAt: now,
    isBossEnabled: false,
    lastDailyRewardAt: 0,
  };
  await db().collection(USERS).doc(uid).set(user);
  return user;
}

/**
 * Atomically deduct tickets. Throws if insufficient balance.
 * Returns the new ticket count.
 */
export async function deductTickets(uid: string, cost: number): Promise<number> {
  if (cost <= 0) return -1; // Nothing to deduct

  const ref = db().collection(USERS).doc(uid);
  let newCount = 0;

  await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "User not found.");
    const data = snap.data() as FirestoreUser;
    if (data.ticketCount < cost) {
      throw new HttpsError("resource-exhausted", `Not enough tickets. Need ${cost}, have ${data.ticketCount}.`);
    }
    newCount = data.ticketCount - cost;
    tx.update(ref, { ticketCount: newCount });
  });

  return newCount;
}

/**
 * Atomically add tickets.
 */
export async function addTickets(uid: string, amount: number): Promise<number> {
  const ref = db().collection(USERS).doc(uid);
  let newCount = 0;

  await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "User not found.");
    const data = snap.data() as FirestoreUser;
    newCount = data.ticketCount + amount;
    tx.update(ref, { ticketCount: newCount });
  });

  return newCount;
}

// ─── PvP helpers ─────────────────────────────────────────────────────────────

export async function getPvpMatch(matchId: string) {
  const doc = await db().collection(PVP_MATCHES).doc(matchId).get();
  if (!doc.exists) throw new HttpsError("not-found", "Match not found.");
  return doc.data() as FirestorePvpMatch;
}

// ─── Types (mirror Dart models) ──────────────────────────────────────────────

export interface FirestoreUser {
  uid: string;
  displayName: string;
  ticketCount: number;
  subscriptionTier: string;
  lastLoginAt: number;
  createdAt: number;
  isBossEnabled: boolean;
  lastDailyRewardAt: number;
}

export interface FirestorePvpMatch {
  matchId: string;
  playerAUid: string;
  playerBUid: string;
  playerARaceName: string;
  playerBRaceName: string;
  playerAStats: Record<string, number>;
  playerBStats: Record<string, number>;
  playerAStrategy: string;
  playerBStrategy: string;
  shortReport: string;
  winner: string;
  status: string;
  createdAt: number;
  expiresAt: number;
}
