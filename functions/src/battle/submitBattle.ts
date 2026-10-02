import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  GEMINI_API_KEY,
  CLAUDE_API_KEY,
  TICKET_COSTS,
  GEMINI_FLASH_LITE,
  GEMINI_FLASH,
} from "../utils/config";
import { callGemini, callClaude } from "../utils/ai";
import { assemblePrompt, formatBattleUserMessage, fetchRemoteConfigData } from "../utils/prompt";
import { deductTickets, addTickets } from "../utils/firestore";
import { parseOutcome, stripResultMarkers } from "../utils/outcome";

interface BattleRequest {
  playerStrategy: string;
  raceStats: Record<string, number>;
  scenarioId: string;
  gameMode: string;
  modelChoice: "gemini" | "claude";
  raceName?: string;
  worldviewKey?: string;
  locale?: string;
}

function maxTokensForMode(gameMode: string): number {
  switch (gameMode) {
  case "practice":
    return 1024;
  case "tabletop":
    return 1024;
  case "pvp":
    return 1024;
  case "epic":
    return 16384;
  case "normal":
  case "boss":
  case "history_puzzle":
  default:
    return 8192;
  }
}

/**
 * submitBattle — the core AI battle judging function.
 *
 * Prompt construction order (spec-compliant):
 *   [System prompt]
 *   1. common_judgment
 *   2. worldview_description
 *   3. mode_addons
 *   4. commander_definition
 *   + output contract (anti-leak + [[RESULT:...]] marker)
 *   [User message]
 *   5. player_stats
 *   6. player_strategy
 */
export const submitBattle = onCall(
  { secrets: [GEMINI_API_KEY, CLAUDE_API_KEY], timeoutSeconds: 120 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    const data = request.data as BattleRequest;

    if (!data.playerStrategy || data.playerStrategy.trim().length === 0) {
      throw new HttpsError("invalid-argument", "Strategy is required.");
    }
    const strategyLen = data.playerStrategy.trim().length;
    if (strategyLen < 5) {
      throw new HttpsError("invalid-argument", "Strategy is too short.");
    }
    if (strategyLen > 2000) {
      throw new HttpsError("invalid-argument", "Strategy exceeds 2000 characters.");
    }
    if (!data.scenarioId || !data.gameMode) {
      throw new HttpsError("invalid-argument", "scenarioId and gameMode are required.");
    }

    if (containsInappropriateContent(data.playerStrategy)) {
      throw new HttpsError("invalid-argument", "CONTENT_FILTER_BLOCKED");
    }
    if (data.raceName && containsInappropriateContent(data.raceName)) {
      throw new HttpsError("invalid-argument", "CONTENT_FILTER_BLOCKED");
    }

    // Soft-validate race stats (30-point budget, 0–10 per stat).
    if (data.raceStats) {
      const values = Object.values(data.raceStats);
      const sum = values.reduce((a, b) => a + (Number(b) || 0), 0);
      if (sum > 30 || values.some((v) => Number(v) < 0 || Number(v) > 10)) {
        throw new HttpsError("invalid-argument", "Invalid raceStats.");
      }
    }

    const gameMode = data.gameMode;
    // Flash-Lite only for short practice/tabletop. history_puzzle needs a real report.
    const useLiteModel = gameMode === "practice" || gameMode === "tabletop";
    const isFreeMode = useLiteModel || gameMode === "history_puzzle";
    const modelChoice = useLiteModel ? "gemini" : (data.modelChoice ?? "gemini");

    const rcData = await fetchRemoteConfigData();
    const rcCosts = rcData.ticket_costs ?? {};
    // Prefer mode-specific cost (boss/epic/normal/pvp), then model keys, then defaults.
    const cost = isFreeMode
      ? (rcCosts["practice"] ?? TICKET_COSTS.practice)
      : modelChoice === "claude"
        ? (rcCosts["claude"] ?? TICKET_COSTS.claude)
        : (rcCosts[gameMode] ??
           rcCosts["gemini"] ??
           (TICKET_COSTS as Record<string, number>)[gameMode] ??
           TICKET_COSTS.gemini);

    const devUids: string[] = (rcData as { dev_uids?: string[] }).dev_uids ?? [];
    const isDevUser = devUids.includes(uid);
    if (cost > 0 && !isDevUser) {
      await deductTickets(uid, cost);
    }

    const worldviewKey = data.worldviewKey ?? "1830_fantasy";
    const basePrompt = await assemblePrompt(worldviewKey, data.scenarioId, gameMode);
    // Pin the output language at both ends.
    //
    // Only the Japanese branch existed. English players got no language
    // instruction at all, and the assembled prompt is largely worldview text
    // written by the client - which is Japanese even in the English fields.
    // With nothing telling it otherwise the model follows the language of its
    // own system prompt, so an English player got English on one battle and
    // Japanese on the next. Observed on device: an English normal battle came
    // back in English, and the epic chronicle right after it came back in
    // Japanese.
    //
    // This does not make the prompt English. It stops the language of the
    // report from depending on it.
    const systemPrompt = data.locale === "ja"
      ? `${basePrompt}\n\n必ず日本語で回答してください。結果マーカー [[RESULT:...]] はそのまま英語形式で出力してください。`
      : `${basePrompt}\n\nAlways write your entire response in English.`;
    const userMessage = formatBattleUserMessage(
      data.playerStrategy,
      data.raceStats,
      data.raceName,
    );

    let reportText: string;
    try {
      const maxTokens = maxTokensForMode(gameMode);
      if (modelChoice === "claude") {
        const rcModels = rcData.model_config ?? {};
        const claudeModel = rcModels["claude"] ?? undefined;
        reportText = await callClaude(
          CLAUDE_API_KEY.value(),
          systemPrompt,
          userMessage,
          claudeModel,
          maxTokens,
        );
      } else {
        const rcModels = rcData.model_config ?? {};
        const modelId = useLiteModel
          ? (rcModels["gemini_flash_lite"] ?? GEMINI_FLASH_LITE)
          : (rcModels["gemini_flash"] ?? GEMINI_FLASH);
        reportText = await callGemini(
          GEMINI_API_KEY.value(),
          systemPrompt,
          userMessage,
          modelId,
          maxTokens,
        );
      }
    } catch (err) {
      console.error("AI call failed:", err);
      await refundTickets(uid, cost, isDevUser);
      throw new HttpsError("internal", "AI service error. Please try again.");
    }

    if (!reportText || !reportText.trim()) {
      console.error("AI returned empty report", { worldviewKey, gameMode, uid });
      await refundTickets(uid, cost, isDevUser);
      throw new HttpsError("internal", "AI returned an empty report. Please try again.");
    }

    const parsed = parseOutcome(reportText);
    if (!parsed) {
      console.error("Failed to parse battle outcome. Raw (truncated):",
        reportText.substring(0, 500));
      await refundTickets(uid, cost, isDevUser);
      throw new HttpsError(
        "internal",
        "OUTCOME_PARSE_FAILED: Could not determine battle result. Please try again.",
      );
    }

    // Strip structured markers from all player-facing text.
    const cleanedReport = stripResultMarkers(reportText);
    const displayReport = gameMode === "tabletop"
      ? cleanedReport.substring(0, 80)
      : cleanedReport;

    if (!displayReport) {
      console.error("Report empty after stripping markers");
      await refundTickets(uid, cost, isDevUser);
      throw new HttpsError("internal", "AI returned an empty report. Please try again.");
    }

    const shortSummary = extractShortSummary(displayReport, gameMode);

    updateLastLogin(uid);
    void updateWinLoss(uid, parsed.outcome);

    return {
      reportText: displayReport,
      outcome: parsed.outcome,
      shortSummary,
      ticketsConsumed: cost,
      worldviewKey,
      ...(parsed.survivalDays !== undefined
        ? { survivalDays: parsed.survivalDays }
        : {}),
    };
  },
);

async function refundTickets(uid: string, cost: number, isDevUser: boolean) {
  if (cost > 0 && !isDevUser) {
    try {
      await addTickets(uid, cost);
      console.log(`Refunded ${cost} ticket(s) to ${uid}.`);
    } catch (refundErr) {
      console.error("Ticket refund failed:", refundErr);
    }
  }
}

const BLACKLIST_EN = [
  "fuck", "shit", "bitch", "nigger", "nigga", "faggot", "retard",
  "kike", "spic", "chink", "whore", "cunt", "bastard", "asshole",
];

const BLACKLIST_JA = ["バカ", "死ね", "クソ", "うざい", "ファック"];

const EN_PATTERNS = BLACKLIST_EN.map(
  (w) => new RegExp(`\\b${w}\\b`, "iu"),
);

function containsInappropriateContent(text: string): boolean {
  if (EN_PATTERNS.some((re) => re.test(text))) return true;
  return BLACKLIST_JA.some((word) => text.includes(word));
}

function extractShortSummary(text: string, gameMode: string): string {
  if (gameMode === "tabletop") {
    return text.trim().substring(0, 60);
  }
  // First sentence, trimmed to 120 characters on a word boundary.
  //
  // This used to cut at exactly 120 characters, which lands mid-word: the
  // result banner read "...but high Life (8) and Streng". Back up to the last
  // space so the summary ends on a whole word. A string with no space in the
  // first 120 characters is a script that does not use them (Japanese), where
  // cutting at the character boundary is already correct.
  const firstSentence = text.split(/[.!？。]/)[0].trim();
  if (firstSentence.length <= 120) return firstSentence;
  const clipped = firstSentence.substring(0, 120);
  const lastSpace = clipped.lastIndexOf(" ");
  return (lastSpace > 60 ? clipped.substring(0, lastSpace) : clipped) + "…";
}

async function updateLastLogin(uid: string) {
  try {
    await admin.firestore()
      .collection("users")
      .doc(uid)
      .update({ lastLoginAt: Date.now() });
  } catch {
    // Non-critical
  }
}

async function updateWinLoss(uid: string, outcome: string) {
  try {
    const ref = admin.firestore().collection("users").doc(uid);
    if (outcome === "win") {
      await ref.update({ totalWins: admin.firestore.FieldValue.increment(1) });
    } else if (outcome === "loss") {
      await ref.update({ totalLosses: admin.firestore.FieldValue.increment(1) });
    }
  } catch (err) {
    console.warn("updateWinLoss failed:", err);
  }
}
