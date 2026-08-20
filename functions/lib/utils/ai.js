"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.callGemini = callGemini;
exports.callClaude = callClaude;
exports.callGeminiFlash = callGeminiFlash;
const generative_ai_1 = require("@google/generative-ai");
const sdk_1 = __importDefault(require("@anthropic-ai/sdk"));
const config_1 = require("./config");
/**
 * Call Gemini with optional cached system prompt.
 * Returns the text response.
 */
async function callGemini(apiKey, systemPrompt, userMessage, modelId = config_1.GEMINI_FLASH_LITE) {
    console.log(`[callGemini] using model: ${modelId}`);
    const genAI = new generative_ai_1.GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
        model: modelId,
        systemInstruction: systemPrompt,
    });
    const result = await model.generateContent(userMessage);
    const response = result.response;
    return response.text();
}
/**
 * Call Claude Haiku.
 * System prompts >= 1024 tokens use Anthropic prompt caching (beta) to
 * reduce cost on repeated identical system prompts across warm invocations.
 */
async function callClaude(apiKey, systemPrompt, userMessage, modelId = config_1.CLAUDE_HAIKU, maxTokens = 1024) {
    // Anthropic prompt caching (beta): mark system prompt for caching so repeated
    // identical prompts are served from Anthropic's cache rather than re-processed.
    // The beta header enables the feature; cache_control marks the cacheable block.
    const anthropicWithCache = new sdk_1.default({
        apiKey,
        defaultHeaders: { "anthropic-beta": "prompt-caching-2024-07-31" },
    });
    const message = await anthropicWithCache.messages.create({
        model: modelId,
        max_tokens: maxTokens,
        system: [
            {
                type: "text",
                text: systemPrompt,
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                cache_control: { type: "ephemeral" },
            },
        ],
        messages: [{ role: "user", content: userMessage }],
    });
    const block = message.content[0];
    if (block.type !== "text")
        throw new Error("Unexpected Claude response type");
    return block.text;
}
/**
 * Call Gemini Flash for PvP (fixed model for fairness).
 */
async function callGeminiFlash(apiKey, systemPrompt, userMessage) {
    return callGemini(apiKey, systemPrompt, userMessage, config_1.GEMINI_FLASH);
}
//# sourceMappingURL=ai.js.map