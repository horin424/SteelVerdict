import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import { japanDateString } from "../utils/japanDay";
import { AiCall, AiLimits, decideAiCall } from "./aiLimits";

/**
 * One document per Japan day ("YYYY-MM-DD"): {day, count, free, updatedAt}.
 * Only the functions write it. Admins read it in the PC admin (firestore.rules).
 */
export const AI_USAGE = "ai_usage";

/**
 * Counts one AI call by [uid] against the daily limits (aiLimits.ts). The
 * player's counters on users/{uid} and today's ai_usage document are updated in
 * one transaction. Call it after the ticket charge, right before the AI.
 *
 * A refusal throws resource-exhausted with the message "<code>:<limit>"
 * (e.g. "DAILY_FREE_LIMIT:30"), which the app turns into its message. The
 * caller gives back any tickets it took. Nothing is counted for a refused call.
 *
 * Every AI call writes today's one ai_usage document. Transactions in the Admin
 * SDK lock what they read, so calls made at the same moment wait their turn,
 * and none is lost.
 */
export async function reserveAiCall(
  uid: string,
  call: AiCall,
  limits: AiLimits,
  db: admin.firestore.Firestore = admin.firestore(),
  now: Date = new Date(),
): Promise<void> {
  const today = japanDateString(now);
  const userRef = db.collection("users").doc(uid);
  const usageRef = db.collection(AI_USAGE).doc(today);

  const decision = await db.runTransaction(async (tx) => {
    const [user, usage] = await tx.getAll(userRef, usageRef);
    if (!user.exists) throw new HttpsError("not-found", "User not found.");
    const d = decideAiCall(
      call, limits, user.data() ?? {}, usage.exists ? usage.data() : undefined, today, now.getTime());
    if (d.allowed) {
      tx.update(userRef, d.user);
      tx.set(usageRef, d.usage);
    }
    return d;
  });

  if (!decision.allowed) {
    console.warn(`AI limit ${decision.code} (${decision.limit}) refused a call by ${uid}.`);
    throw new HttpsError("resource-exhausted", `${decision.code}:${decision.limit}`);
  }
}
