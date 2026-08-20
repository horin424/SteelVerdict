import { onCall, HttpsError } from "firebase-functions/v2/https";
import { CLAUDE_API_KEY, CLAUDE_HAIKU } from "../utils/config";
import { callClaude } from "../utils/ai";
import { deductTickets, getUser } from "../utils/firestore";

interface GenerateWarHistoryRequest {
  battleTitle: string;
  playerStrategy: string;
  raceStats: Record<string, number>;
  raceName: string;
  opponentName: string;
  outcome: string; // "win" | "loss" | "draw"
  scenarioId?: string;
  shortReport?: string;
}

// Cost: 3 tickets (same as Claude) — or free for ¥3000/mo subscribers
const WAR_HISTORY_TICKET_COST = 3;

/**
 * generateWarHistory — creates a 3000-char official war history narrative.
 *
 * Uses Claude Haiku for rich, narrative prose quality.
 * Subscription ¥3000/mo → unlimited (cost = 0).
 * Otherwise costs 3 tickets per generation.
 */
export const generateWarHistory = onCall(
  { secrets: [CLAUDE_API_KEY], timeoutSeconds: 120 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    const data = request.data as GenerateWarHistoryRequest;

    if (!data.playerStrategy || !data.raceName) {
      throw new HttpsError("invalid-argument", "playerStrategy and raceName are required.");
    }

    // Check subscription tier
    const user = await getUser(uid);
    const isUnlimited = user.subscriptionTier === "sub3000";
    const cost = isUnlimited ? 0 : WAR_HISTORY_TICKET_COST;

    if (cost > 0) {
      await deductTickets(uid, cost);
    }

    const statsText = Object.entries(data.raceStats)
      .map(([k, v]) => `${k}: ${v}`)
      .join(", ");

    const outcomeWord =
      data.outcome === "win" ? "VICTORY"
        : data.outcome === "loss" ? "DEFEAT"
          : "STALEMATE";

    const systemPrompt = `You are a prestigious military historian writing official war chronicles.
Write in a formal, epic narrative style — as if this battle will be remembered for centuries.
Use vivid, dramatic language. Describe the terrain, weather, troop movements, and the turning point of the battle.
The chronicle should be approximately 3000 characters long.
Do NOT use markdown headers or bullet points. Write continuous flowing prose.
End with a paragraph reflecting on the historical significance of this battle.`;

    const userMessage = `Write an official war history chronicle for the following battle:

Title: ${data.battleTitle}
Commander's Race: ${data.raceName}
Race Statistics: ${statsText}
Opponent: ${data.opponentName || "Unknown Enemy"}
Outcome: ${outcomeWord}
Strategy Employed: ${data.playerStrategy}
${data.shortReport ? `Battle Summary: ${data.shortReport}` : ""}

Write the full chronicle now (approximately 3000 characters):`;

    let chronicleText: string;
    try {
      chronicleText = await callClaude(
        CLAUDE_API_KEY.value(),
        systemPrompt,
        userMessage,
        CLAUDE_HAIKU,
        1500, // ~3000 chars ≈ 1500 tokens
      );
    } catch (err) {
      console.error("generateWarHistory AI error:", err);
      throw new HttpsError("internal", "Failed to generate war history. Please try again.");
    }

    return {
      chronicleText,
      ticketsConsumed: cost,
    };
  },
);
