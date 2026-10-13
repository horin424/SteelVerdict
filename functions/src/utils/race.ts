import { HttpsError } from "firebase-functions/v2/https";
import { containsInappropriateContent } from "./contentFilter";

// The app's race limits (lib/core/constants/app_constants.dart).
const MAX_STAT_POINTS = 30;
const MAX_STAT_VALUE = 10;
const MIN_RACE_NAME_LENGTH = 2;
const MAX_RACE_NAME_LENGTH = 20;

/**
 * Throws invalid-argument unless every stat is a whole number from 0 to 10
 * and they add up to 30 or less.
 */
export function checkRaceStats(stats: unknown): void {
  const values = stats !== null && typeof stats === "object" && !Array.isArray(stats)
    ? Object.values(stats as Record<string, unknown>)
    : null;
  const valid = values !== null &&
    values.every((v) => Number.isInteger(v) && (v as number) >= 0 && (v as number) <= MAX_STAT_VALUE) &&
    values.reduce((sum: number, v) => sum + (v as number), 0) <= MAX_STAT_POINTS;
  if (!valid) {
    throw new HttpsError("invalid-argument", "Invalid raceStats.");
  }
}

/** Returns the trimmed name, or throws if the app would not have accepted it. */
export function checkRaceName(name: unknown): string {
  const trimmed = typeof name === "string" ? name.trim() : "";
  if (trimmed.length < MIN_RACE_NAME_LENGTH || trimmed.length > MAX_RACE_NAME_LENGTH) {
    throw new HttpsError("invalid-argument", "Invalid raceName.");
  }
  if (containsInappropriateContent(trimmed)) {
    throw new HttpsError("invalid-argument", "CONTENT_FILTER_BLOCKED");
  }
  return trimmed;
}
