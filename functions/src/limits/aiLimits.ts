/**
 * The daily AI limits (client point 2, 20 Nov 2026; release_scope 11).
 *
 * Every AI call a player starts, a battle (submitBattle) or a chronicle
 * (generateWarHistory), is counted for that player and for the whole app, per
 * Japan day. The modes that cost no ticket used to call the AI without any limit:
 * their limits were only in the app, so a modified app or a script skipped them.
 *
 * The three numbers are kept in system_config/game_config under ai_daily_limits
 * and are edited in the PC admin. A missing or invalid number uses its default
 * below; 0 allows none. Nothing here touches Firestore, so it is checked offline
 * (scripts/verify-ai-limits.js). reserveAiCall.ts applies it in a transaction.
 */

/** The game_config section that holds the limits. */
export const AI_LIMITS_SECTION = "ai_daily_limits";

export type AiLimits = {
  /** Per player and day: battles that charge no ticket (practice, tabletop, history_puzzle). */
  freePerUser: number;
  /** Per player and day: every AI call, battles of all modes and chronicles. */
  allPerUser: number;
  /** The whole app per day: every AI call, all players together. */
  appTotal: number;
};

/** The starting numbers, as proposed to the client on 20 Nov 2026. */
export const AI_LIMIT_DEFAULTS: AiLimits = { freePerUser: 30, allPerUser: 100, appTotal: 3000 };

/** The stored key of each limit (snake_case, like ticket_costs and model_config). */
export const AI_LIMIT_KEYS: Record<keyof AiLimits, string> = {
  freePerUser: "free_per_user",
  allPerUser: "all_per_user",
  appTotal: "app_total",
};

/** Sent to the app as "<code>:<limit>", e.g. "DAILY_FREE_LIMIT:30". */
export type AiLimitCode = "DAILY_FREE_LIMIT" | "DAILY_AI_LIMIT" | "APP_AI_LIMIT";

/** The limits in the stored section. Each missing or invalid number uses its default. */
export function readAiLimits(section: unknown): AiLimits {
  const stored = section !== null && typeof section === "object" && !Array.isArray(section)
    ? section as Record<string, unknown>
    : {};
  const pick = (key: keyof AiLimits): number => {
    const v = stored[AI_LIMIT_KEYS[key]];
    return typeof v === "number" && Number.isFinite(v) && v >= 0 ? Math.floor(v) : AI_LIMIT_DEFAULTS[key];
  };
  return { freePerUser: pick("freePerUser"), allPerUser: pick("allPerUser"), appTotal: pick("appTotal") };
}

/** A stored count. Anything but a positive number counts as 0. */
function storedCount(v: unknown): number {
  return typeof v === "number" && Number.isFinite(v) && v > 0 ? Math.floor(v) : 0;
}

export type AiCall = {
  /** A battle that charges no ticket. */
  free: boolean;
  /** An account in dev_uids: no per-player limits. It is still counted, and the app's limit applies. */
  dev: boolean;
};

/** The player's counters, kept on users/{uid}. */
export type UserAiCounts = { aiCallsDate: string; aiCallsCount: number; aiFreeCallsCount: number };

/** The day's ai_usage document. */
export type AiUsageDay = { day: string; count: number; free: number; updatedAt: number };

export type AiCallDecision =
  | { allowed: true; user: UserAiCounts; usage: AiUsageDay }
  | { allowed: false; code: AiLimitCode; limit: number };

/**
 * Whether one more AI call is allowed, and if so the counts to store.
 *
 * [user] is the player's document, [usage] today's ai_usage document (undefined
 * when there is none yet), [today] the Japan day, [now] the time in ms. The
 * player's limits are checked first (the free one, then all), then the app's.
 */
export function decideAiCall(
  call: AiCall,
  limits: AiLimits,
  user: Record<string, unknown>,
  usage: Record<string, unknown> | undefined,
  today: string,
  now: number,
): AiCallDecision {
  const sameDay = user.aiCallsDate === today;
  const all = sameDay ? storedCount(user.aiCallsCount) : 0;
  const free = sameDay ? storedCount(user.aiFreeCallsCount) : 0;
  const appAll = storedCount(usage?.count);
  const appFree = storedCount(usage?.free);

  if (!call.dev) {
    if (call.free && free >= limits.freePerUser) {
      return { allowed: false, code: "DAILY_FREE_LIMIT", limit: limits.freePerUser };
    }
    if (all >= limits.allPerUser) {
      return { allowed: false, code: "DAILY_AI_LIMIT", limit: limits.allPerUser };
    }
  }
  if (appAll >= limits.appTotal) {
    return { allowed: false, code: "APP_AI_LIMIT", limit: limits.appTotal };
  }

  const add = call.free ? 1 : 0;
  return {
    allowed: true,
    user: { aiCallsDate: today, aiCallsCount: all + 1, aiFreeCallsCount: free + add },
    usage: { day: today, count: appAll + 1, free: appFree + add, updatedAt: now },
  };
}
