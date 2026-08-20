import { defineSecret } from "firebase-functions/params";

// Store API keys as Firebase Secrets (never in code)
// Set via: firebase functions:secrets:set GEMINI_API_KEY
export const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
export const CLAUDE_API_KEY = defineSecret("CLAUDE_API_KEY");

// Google Play / Apple shared secret for receipt validation
export const GOOGLE_PLAY_SERVICE_ACCOUNT = defineSecret("GOOGLE_PLAY_SERVICE_ACCOUNT");
export const APPLE_SHARED_SECRET = defineSecret("APPLE_SHARED_SECRET");

// Ticket costs per model (can be overridden via Remote Config on client)
export const TICKET_COSTS = {
  gemini: 1,
  claude: 3,
  practice: 0,
  tabletop: 0, // ad covers it; skip costs 1 — handled client-side
  pvp: 1,       // fixed Gemini Flash for fairness
};

// Model IDs
export const GEMINI_FLASH_LITE = "gemini-2.5-flash-lite";
export const GEMINI_FLASH     = "gemini-2.5-flash";
export const CLAUDE_HAIKU     = "claude-haiku-4-5-20251001";
