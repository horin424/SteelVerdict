/**
 * Reports of AI output (the app's 「報告」 button on the battle result and war
 * history screens). Google Play's AI-Generated Content policy asks apps that
 * generate content with AI to let users report offensive output to the
 * developer without leaving the app.
 *
 * The battle reports and chronicles live only on the player's phone, so a
 * report carries the text itself. This file checks what the app sends; it
 * has no Firebase in it, so scripts/verify-ai-report.js checks it offline.
 */

export const REPORT_KINDS = ["battle", "chronicle"] as const;
export const REPORT_REASONS = ["offensive", "violence", "sexual", "other"] as const;
export type ReportKind = (typeof REPORT_KINDS)[number];
export type ReportReason = (typeof REPORT_REASONS)[number];

/** Far above any AI report or chronicle; only stops abuse (a Firestore document holds 1 MiB). */
export const MAX_AI_TEXT = 50_000;
/** As the app's strategy box (AppConstants.maxStrategyLength). */
export const MAX_STRATEGY = 2_000;
export const MAX_COMMENT = 500;
/** gameMode, scenarioId, worldviewKey, appVersion. */
export const MAX_LABEL = 100;
/** Reports per account per day (Japan date), so the list can't be flooded. */
export const MAX_REPORTS_PER_DAY = 20;

/** What is stored, besides the uid, the time and the status. */
export interface AiReport {
  kind: ReportKind;
  reason: ReportReason;
  aiText: string;
  strategy: string;
  comment: string;
  gameMode: string;
  scenarioId: string;
  worldviewKey: string;
  appVersion: string;
}

export type AiReportRefusal =
  | "invalid_request" | "invalid_kind" | "invalid_reason" | "empty_text" | "text_too_long"
  | "strategy_too_long" | "comment_too_long" | "invalid_label";

/** An optional text: missing or null is "", anything but a string is refused. */
function text(data: Record<string, unknown>, key: string): string | null {
  const v = data[key];
  if (v === undefined || v === null) return "";
  return typeof v === "string" ? v : null;
}

/** The report the app sent, cleaned up, or why it is refused. */
export function checkAiReport(data: unknown): { report: AiReport } | { refusal: AiReportRefusal } {
  if (!data || typeof data !== "object" || Array.isArray(data)) return { refusal: "invalid_request" };
  const d = data as Record<string, unknown>;

  const kind = d.kind;
  if (typeof kind !== "string" || !(REPORT_KINDS as readonly string[]).includes(kind)) return { refusal: "invalid_kind" };
  const reason = d.reason;
  if (typeof reason !== "string" || !(REPORT_REASONS as readonly string[]).includes(reason)) {
    return { refusal: "invalid_reason" };
  }

  const aiText = text(d, "aiText");
  if (aiText === null || !aiText.trim()) return { refusal: "empty_text" };
  if (aiText.length > MAX_AI_TEXT) return { refusal: "text_too_long" };

  const strategy = text(d, "strategy");
  if (strategy === null || strategy.length > MAX_STRATEGY) return { refusal: "strategy_too_long" };
  const comment = text(d, "comment");
  if (comment === null || comment.trim().length > MAX_COMMENT) return { refusal: "comment_too_long" };

  const labels: Record<string, string> = {};
  for (const key of ["gameMode", "scenarioId", "worldviewKey", "appVersion"]) {
    const v = text(d, key);
    if (v === null || v.length > MAX_LABEL) return { refusal: "invalid_label" };
    labels[key] = v.trim();
  }

  return {
    report: {
      kind: kind as ReportKind,
      reason: reason as ReportReason,
      aiText,
      strategy,
      comment: comment.trim(),
      gameMode: labels.gameMode,
      scenarioId: labels.scenarioId,
      worldviewKey: labels.worldviewKey,
      appVersion: labels.appVersion,
    },
  };
}

/** The user document's report counter for [today]: whether one more is allowed, and the fields to write. */
export function reportCount(
  user: { aiReportsDate?: unknown; aiReportsCount?: unknown }, today: string,
): { allowed: true; update: { aiReportsDate: string; aiReportsCount: number } } | { allowed: false } {
  const count = user.aiReportsDate === today && typeof user.aiReportsCount === "number" ? user.aiReportsCount : 0;
  if (count >= MAX_REPORTS_PER_DAY) return { allowed: false };
  return { allowed: true, update: { aiReportsDate: today, aiReportsCount: count + 1 } };
}
