import { GoogleGenerativeAI } from "@google/generative-ai";
import Anthropic from "@anthropic-ai/sdk";
import { GEMINI_FLASH_LITE, GEMINI_FLASH, CLAUDE_HAIKU } from "./config";

/**
 * Call Gemini with optional cached system prompt.
 * Returns the text response.
 */
export async function callGemini(
  apiKey: string,
  systemPrompt: string,
  userMessage: string,
  modelId: string = GEMINI_FLASH_LITE,
  maxTokens = 1024,
): Promise<string> {
  console.log(`[callGemini] using model: ${modelId}`);
  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: modelId,
    systemInstruction: systemPrompt,
    generationConfig: { maxOutputTokens: maxTokens },
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
export async function callClaude(
  apiKey: string,
  systemPrompt: string,
  userMessage: string,
  modelId: string = CLAUDE_HAIKU,
  maxTokens = 1024,
): Promise<string> {
  // Anthropic prompt caching (beta): mark system prompt for caching so repeated
  // identical prompts are served from Anthropic's cache rather than re-processed.
  // The beta header enables the feature; cache_control marks the cacheable block.
  const anthropicWithCache = new Anthropic({
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
        cache_control: { type: "ephemeral" } as any,
      },
    ],
    messages: [{ role: "user", content: userMessage }],
  });

  const block = message.content[0];
  if (block.type !== "text") throw new Error("Unexpected Claude response type");
  return block.text;
}

/**
 * Call Gemini Flash for PvP (fixed model for fairness).
 */
export async function callGeminiFlash(
  apiKey: string,
  systemPrompt: string,
  userMessage: string,
): Promise<string> {
  return callGemini(apiKey, systemPrompt, userMessage, GEMINI_FLASH);
}
