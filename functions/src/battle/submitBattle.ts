import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { GEMINI_API_KEY, CLAUDE_API_KEY, TICKET_COSTS, GEMINI_FLASH_LITE, GEMINI_FLASH } from "../utils/config";
import { callGemini, callClaude } from "../utils/ai";
import { assemblePrompt, formatBattleUserMessage, fetchRemoteConfigData } from "../utils/prompt";
import { deductTickets, addTickets } from "../utils/firestore";

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

/**
 * submitBattle — the core AI battle judging function.
 *
 * Prompt construction order (spec-compliant):
 *   [System prompt]
 *   1. common_judgment          — worldview judgment rules (Remote Config)
 *   2. worldview_description    — setting/era description (Remote Config)
 *   3. mode_addons              — mode-specific instructions (Remote Config)
 *   4. commander_definition     — enemy general character (Remote Config, if applicable)
 *   [User message]
 *   5. player_stats             — race name + stat values
 *   6. player_strategy          — the player's submitted strategy text
 *
 * Flow:
 *   1. Verify auth
 *   2. Validate input + content filter
 *   3. Calculate ticket cost
 *   4. Deduct tickets (atomic transaction — prevents fraud)
 *   5. Assemble system prompt from Remote Config (parts 1-4)
 *   6. Format user message (parts 5-6)
 *   7. Call AI model
 *   8. On AI failure → REFUND tickets, throw error
 *   9. Parse outcome from response
 *   10. Return BattleResponse
 */
export const submitBattle = onCall(
  { secrets: [GEMINI_API_KEY, CLAUDE_API_KEY], timeoutSeconds: 120 },
  async (request) => {
    // 1. Auth check
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    const data = request.data as BattleRequest;

    // 2. Input validation
    if (!data.playerStrategy || data.playerStrategy.trim().length === 0) {
      throw new HttpsError("invalid-argument", "Strategy is required.");
    }
    if (!data.scenarioId || !data.gameMode) {
      throw new HttpsError("invalid-argument", "scenarioId and gameMode are required.");
    }

    // 2b. Content filter — blacklist check
    if (containsInappropriateContent(data.playerStrategy)) {
      throw new HttpsError("invalid-argument", "CONTENT_FILTER_BLOCKED");
    }
    if (data.raceName && containsInappropriateContent(data.raceName)) {
      throw new HttpsError("invalid-argument", "CONTENT_FILTER_BLOCKED");
    }

    const gameMode = data.gameMode;
    const isPractice = gameMode === "practice" || gameMode === "tabletop" || gameMode === "history_puzzle";
    const modelChoice = isPractice ? "gemini" : (data.modelChoice ?? "gemini");

    // 3. Ticket cost — prefer Remote Config, fall back to hardcoded defaults
    const rcData = await fetchRemoteConfigData();
    const rcCosts = rcData.ticket_costs ?? {};
    const cost = isPractice
      ? (rcCosts["practice"] ?? TICKET_COSTS.practice)
      : modelChoice === "claude"
        ? (rcCosts["claude"] ?? TICKET_COSTS.claude)
        : (rcCosts["gemini"] ?? TICKET_COSTS.gemini);

    // 4. Deduct tickets (skipped for practice and dev UIDs)
    const devUids: string[] = (rcData as any).dev_uids ?? [];
    const isDevUser = devUids.includes(uid);
    if (cost > 0 && !isDevUser) {
      await deductTickets(uid, cost);
    }

    // 5. Assemble prompt
    const worldviewKey = data.worldviewKey ?? "1830_fantasy";
    const basePrompt = await assemblePrompt(worldviewKey, data.scenarioId, gameMode);
    const systemPrompt = data.locale === "ja"
      ? `${basePrompt}\n\n必ず日本語で回答してください。`
      : basePrompt;
    const userMessage = formatBattleUserMessage(
      data.playerStrategy,
      data.raceStats,
      data.raceName,
    );

    // 7. Call AI — refund tickets if the API fails
    let reportText: string;
    try {
      const maxTokens = gameMode === "epic" ? 2048 : 1024;
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
        const modelId = isPractice
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
      // Refund tickets — spec: "If the API fails → ticket must be refunded"
      if (cost > 0 && !isDevUser) {
        try {
          await addTickets(uid, cost);
          console.log(`Refunded ${cost} ticket(s) to ${uid} after AI failure.`);
        } catch (refundErr) {
          console.error("Ticket refund failed:", refundErr);
        }
      }
      throw new HttpsError("internal", "AI service error. Please try again.");
    }

    // 7. Parse outcome keyword from the AI response
    const outcome = parseOutcome(reportText);

    // 8. Short summary (first sentence or first 120 chars)
    const shortSummary = extractShortSummary(reportText, gameMode);

    // Update lastLoginAt for PvP matching priority (fire-and-forget)
    updateLastLogin(uid);

    return {
      reportText,
      outcome,
      shortSummary,
      ticketsConsumed: cost,
    };
  },
);

// ─── Content filter ───────────────────────────────────────────────────────────

const BLACKLIST = [
  "fuck", "shit", "bitch", "nigger", "nigga", "faggot", "retard",
  "kike", "spic", "chink", "whore", "cunt", "bastard", "asshole",
  // Japanese
  "バカ", "死ね", "クソ", "うざい", "殺す", "ファック",
];

function containsInappropriateContent(text: string): boolean {
  const lower = text.toLowerCase();
  return BLACKLIST.some((word) => lower.includes(word));
}

// ─── Outcome parsing ──────────────────────────────────────────────────────────

function parseOutcome(text: string): "win" | "loss" | "draw" {
  const upper = text.toUpperCase();
  if (upper.includes("VICTORY") || upper.includes("WIN") || upper.includes("VICTORIOUS")) {
    return "win";
  }
  if (upper.includes("DEFEAT") || upper.includes("LOSS") || upper.includes("LOST") || upper.includes("ROUTED")) {
    return "loss";
  }
  return "draw";
}

function extractShortSummary(text: string, gameMode: string): string {
  if (gameMode === "tabletop") {
    // For tabletop, the whole response IS the win rate (~20 chars)
    return text.trim().substring(0, 60);
  }
  // First sentence up to 120 chars
  const firstSentence = text.split(/[.!？。]/)[0].trim();
  return firstSentence.substring(0, 120);
}

async function updateLastLogin(uid: string) {
  try {
    await admin.firestore()
      .collection("users")
      .doc(uid)
      .update({ lastLoginAt: Date.now() });
  } catch {
    // Non-critical — ignore
  }
}
