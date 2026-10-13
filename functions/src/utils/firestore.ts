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

/** A new player's name: guests get none, and the app shows its own default (匿名司令官). */
export function startingName(user: { displayName?: string; email?: string }): string {
  return user.displayName || user.email?.split("@")[0] || "";
}

function startingUser(uid: string, displayName: string): FirestoreUser {
  const now = Date.now();
  return {
    uid,
    displayName: displayName || "",
    ticketCount: 3, // Starting tickets
    subscriptionTier: "free",
    lastLoginAt: now,
    createdAt: now,
    isBossEnabled: false,
    lastDailyRewardAt: 0,
  };
}

export async function createUserDoc(uid: string, displayName: string) {
  const user = startingUser(uid, displayName);
  await db().collection(USERS).doc(uid).set(user);
  return user;
}

/**
 * Creates the player's document with the starting values if it is missing.
 *
 * onUserCreated creates it at sign-up. When that trigger failed, every call
 * for the account failed with "User not found", for good. The callables that
 * use the document call this first. A deleted account is not brought back.
 */
export async function ensureUserDoc(uid: string): Promise<void> {
  const ref = db().collection(USERS).doc(uid);
  if ((await ref.get()).exists) return;

  let authUser: admin.auth.UserRecord;
  try {
    authUser = await admin.auth().getUser(uid);
  } catch {
    throw new HttpsError("not-found", "User not found.");
  }
  try {
    await ref.create(startingUser(uid, startingName(authUser)));
    console.warn(`ensureUserDoc: created the missing user document for ${uid}`);
  } catch (err) {
    // 6 = ALREADY_EXISTS: a parallel call created it first, which is fine.
    if ((err as { code?: number }).code !== 6) throw err;
  }
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
  /** Tickets each player paid to submit; absent on matches from before it was kept. */
  playerATicketsPaid?: number;
  playerBTicketsPaid?: number;
  shortReport: string;
  winner: string;
  status: string;
  createdAt: number;
  expiresAt: number;
  /** Optional — when set, PvP judging uses this worldview instead of fantasy. */
  worldviewKey?: string;
}
