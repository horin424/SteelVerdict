import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { ensureUserDoc } from "../utils/firestore";
import { fetchRemoteConfigData } from "../utils/prompt";

/**
 * The scenario pack (古代バトルパック): after buying it, the player picks the
 * scenarios it unlocks. The picks are saved to the account, so they come back
 * after a reinstall or on another phone, and they are final: the client chose
 * "can't be changed later" (28 Oct 2026).
 */

/** How many scenarios the pack unlocks. */
export const PACK_SIZE = 5;

/** users/{uid}: the scenario IDs picked with the pack, and when (ms). */
export const PACK_PICKS_FIELD = "scenarioPack1Picks";
export const PACK_PICKED_AT_FIELD = "scenarioPack1PickedAt";

interface ScenarioFlags {
  scenarioId?: unknown;
  isFree?: unknown;
  is_free?: unknown;
  isUnlocked?: unknown;
  is_unlocked?: unknown;
}

const flag = (a: unknown, b: unknown): boolean =>
  typeof a === "boolean" ? a : typeof b === "boolean" ? b : false;

/**
 * The scenarios a player has to unlock: not free and not unlocked for
 * everyone. Reads the flags and IDs the way the app does (ScenarioModel).
 */
export function lockedScenarioIds(scenarios: Record<string, unknown>): Set<string> {
  const ids = new Set<string>();
  for (const [key, raw] of Object.entries(scenarios ?? {})) {
    if (!raw || typeof raw !== "object") continue;
    const s = raw as ScenarioFlags;
    const id = typeof s.scenarioId === "string" && s.scenarioId ? s.scenarioId : key;
    if (!flag(s.isFree, s.is_free) && !flag(s.isUnlocked, s.is_unlocked)) ids.add(id);
  }
  return ids;
}

/**
 * Checks a choice against the locked scenarios: exactly PACK_SIZE different
 * locked scenarios, or all of them when fewer are locked. Returns the IDs, or
 * the reason the choice is refused.
 */
export function checkPicks(raw: unknown, locked: Set<string>): { ids: string[] } | { reason: string } {
  if (!Array.isArray(raw) || raw.some((x) => typeof x !== "string" || !x)) {
    return { reason: "invalid_picks" };
  }
  const ids = [...new Set(raw as string[])];
  if (ids.length !== raw.length) return { reason: "duplicate_picks" };
  const wanted = Math.min(PACK_SIZE, locked.size);
  if (wanted === 0) return { reason: "nothing_to_pick" };
  if (ids.length !== wanted) return { reason: "wrong_count" };
  if (ids.some((id) => !locked.has(id))) return { reason: "not_locked" };
  return { ids };
}

/**
 * chooseScenarioPack — saves the scenarios picked with the scenario pack.
 * Refused unless the account owns the pack, and once picks are saved.
 * In: { scenarioIds: string[] }. Out: { scenarioIds }.
 */
export const chooseScenarioPack = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const uid = request.auth.uid;
  await ensureUserDoc(uid);

  const config = await fetchRemoteConfigData();
  const checked = checkPicks(request.data?.scenarioIds, lockedScenarioIds(config.scenarios ?? {}));
  if ("reason" in checked) throw new HttpsError("invalid-argument", checked.reason);

  const ref = admin.firestore().collection("users").doc(uid);
  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "User not found.");
    if (snap.get("scenarioPack1Unlocked") !== true) {
      throw new HttpsError("failed-precondition", "pack_not_owned");
    }
    const saved = snap.get(PACK_PICKS_FIELD);
    if (Array.isArray(saved) && saved.length > 0) {
      throw new HttpsError("already-exists", "already_chosen");
    }
    tx.update(ref, { [PACK_PICKS_FIELD]: checked.ids, [PACK_PICKED_AT_FIELD]: Date.now() });
  });

  return { scenarioIds: checked.ids };
});
