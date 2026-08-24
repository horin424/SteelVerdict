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

// Output budget for AI-written reports.
//
// The 2.5 models are thinking models: their reasoning tokens are drawn from the
// same maxOutputTokens allowance as the visible answer. The prompts ask for a
// report of 1000+ Japanese characters, which is roughly 1000-1500 tokens on its
// own, so a small ceiling leaves nothing for the report.
//
// These were 1024 / 2048. At 1024 the model spent nearly the whole budget
// thinking and returned two or three lines that stopped mid-sentence - before
// the trailing VICTORY / DEFEAT / STALEMATE keyword the prompts ask it to end
// on. parseOutcome then found no verdict and fell through to "draw", so battles
// the player had plainly won were scored as draws.
//
// Why this was not visible until recently: functions/lib is compiled output but
// is committed, and the tracked build had gone stale. Its callGemini took no
// maxTokens and set no generationConfig at all, so Gemini ran with the model's
// own (much larger) default. firebase.json rebuilds lib from src on every
// deploy, so the first deploy after that drift shipped the 1024 ceiling to
// production for the first time. The Claude path always passed it, so only
// Gemini changed behaviour - and Gemini is the default model.
//
// The ceiling is kept rather than removed, because an explicit bound is what the
// original author intended; it is simply raised to fit thinking plus the report.
// The proper fix is to stop thinking from competing with the answer at all
// (thinkingConfig.thinkingBudget), which @google/generative-ai 0.21 does not
// expose - it needs the newer @google/genai SDK.
export const REPORT_MAX_TOKENS = 8192;
export const EPIC_MAX_TOKENS   = 16384;

// The chronicle prompt asks for roughly 3000 characters. This was 1500, with
// the comment "~3000 chars = 1500 tokens" - a ratio that holds for English and
// is backwards for Japanese, where a character is around a token or more. The
// Japanese chronicle therefore ran out mid-word; one observed ending was the
// fragment "指揮官のWis".
export const CHRONICLE_MAX_TOKENS = 6144;
