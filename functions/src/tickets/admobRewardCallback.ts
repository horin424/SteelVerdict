import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
// From the module itself: in the functions emulator, admin.firestore.Timestamp is undefined (its stub of
// firebase-admin drops it), and the local run of 20 Nov 2026 answered 500 to every reward.
import { Timestamp } from "firebase-admin/firestore";
import { japanDateString } from "../utils/japanDay";
import {
  AdReward, KeyStore, REWARD_RECORD_DAYS, adTicketDecision, createKeyStore, fetchVerifierKeys,
  readReward, rewardRefusal, signatureValid, splitSignedQuery,
} from "./adReward";

/** Every reward that reached the server, by AdMob's transaction_id. Server-only (no rule lets the app in). */
const AD_REWARDS = "ad_rewards";

export type GrantOutcome = "granted" | "daily_cap" | "duplicate" | "no_user";

/**
 * Adds the tickets for one verified reward: once per transaction_id (AdMob
 * may send the same reward again), at most 20 a day. The record and the
 * tickets are written in one transaction. A user without a document gets
 * nothing (the uid comes from the app, so no document is made for it).
 */
export async function grantAdTickets(
  db: admin.firestore.Firestore, reward: AdReward, now: Date = new Date(),
): Promise<GrantOutcome> {
  const userRef = db.collection("users").doc(reward.userId);
  const recordRef = db.collection(AD_REWARDS).doc(reward.transactionId);
  return db.runTransaction(async (tx) => {
    const [record, user] = await tx.getAll(recordRef, userRef);
    if (record.exists) return "duplicate";
    if (!user.exists) return "no_user";
    const decision = adTicketDecision(user.data() ?? {}, japanDateString(now));
    tx.create(recordRef, {
      granted: decision.granted,
      adUnit: reward.adUnit,
      rewardedAt: reward.rewardedAt,
      receivedAt: now.getTime(),
      expireAt: Timestamp.fromMillis(now.getTime() + REWARD_RECORD_DAYS * 24 * 60 * 60 * 1000),
    });
    if (decision.granted) tx.update(userRef, decision.update);
    return decision.granted ? "granted" : "daily_cap";
  });
}

export interface CallbackRequest {
  method: string;
  originalUrl?: string;
  url?: string;
}

export interface CallbackResponse {
  status(code: number): { send(body: string): unknown };
}

export interface CallbackDeps {
  keys: KeyStore;
  grant: (reward: AdReward) => Promise<GrantOutcome>;
  now?: () => number;
}

/**
 * One call from AdMob. 200 for every reward Google signed, also when it adds
 * no tickets (a scenario-unlock ad, the day's 20 used, the same reward again),
 * so AdMob doesn't send it again; 403 for a wrong signature; 500 when Google's
 * keys or Firestore fail (AdMob tries up to 5 more times, 1 second apart).
 */
export async function handleAdRewardCallback(
  req: CallbackRequest, res: CallbackResponse, deps: CallbackDeps,
): Promise<void> {
  if (req.method !== "GET") {
    res.status(405).send("GET only");
    return;
  }
  const url = req.originalUrl ?? req.url ?? "";
  const q = url.indexOf("?");
  const signed = splitSignedQuery(q < 0 ? "" : url.slice(q + 1));
  if (!signed) {
    console.warn("Ad reward: not a signed AdMob callback");
    res.status(400).send("bad request");
    return;
  }

  let key;
  try {
    key = await deps.keys.get(signed.keyId);
  } catch (err) {
    console.error("Ad reward: Google's verifier keys can't be loaded", err);
    res.status(500).send("try again");
    return;
  }
  if (!key || !signatureValid(signed.message, signed.signature, key)) {
    console.warn(`Ad reward: signature refused (key_id ${signed.keyId}${key ? "" : ", not one of Google's keys"})`);
    res.status(403).send("forbidden");
    return;
  }

  const reward = readReward(signed.message);
  const refusal = rewardRefusal(reward, (deps.now ?? Date.now)());
  if (refusal) {
    console.log(`Ad reward: no tickets (${refusal}), ad unit ${reward.adUnit}, transaction ${reward.transactionId}`);
    res.status(200).send("ok");
    return;
  }

  let outcome: GrantOutcome;
  try {
    outcome = await deps.grant(reward);
  } catch (err) {
    console.error(`Ad reward: tickets not added, transaction ${reward.transactionId}`, err);
    res.status(500).send("try again");
    return;
  }
  console.log(`Ad reward: ${outcome}, user ${reward.userId}, transaction ${reward.transactionId}`);
  res.status(200).send("ok");
}

const keys = createKeyStore(() => fetchVerifierKeys());

/**
 * admobRewardCallback: the server-side verification URL set on the rewarded
 * ad unit in AdMob. Public, because AdMob calls it without a sign-in; Google's
 * signature is the check.
 */
export const admobRewardCallback = onRequest({ invoker: "public" }, (req, res) =>
  handleAdRewardCallback(req, res, {
    keys,
    grant: (reward) => grantAdTickets(admin.firestore(), reward),
  }));
