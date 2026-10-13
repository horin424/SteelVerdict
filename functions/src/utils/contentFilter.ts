// Words refused in strategies and race names. The same list as the app
// (lib/core/utils/content_filter.dart). Keep the two in step, so the server
// never refuses text the app has already accepted.

/** Matched as whole words, so "assault", "cockpit" and "Wessex" pass. */
export const WORDS = [
  "fuck", "shit", "bitch", "bastard", "asshole", "dick", "cock", "pussy",
  "nigger", "nigga", "faggot", "retard", "kike", "spic", "chink",
  "slut", "whore", "cunt", "penis", "vagina", "sex", "porn", "nude", "naked", "rape",
];

/**
 * Japanese has no word boundaries, so each term carries its own guard against
 * the ordinary words it sits inside.
 */
export const JA_PATTERNS = [
  "くそ(?!ま)", // not くそまじめ
  "クソ",
  "ばか(?!り|らしい)", // not ばかり, ばからしい
  "バカ(?!リ|ンス)", // not バカンス
  "アホ(?!ウドリ)", // not アホウドリ (albatross)
  "あほ(?!うどり)",
  "きちく",
  "ちくしょう",
  "死ね(?![ばなるま])", // not 死ねば, 死ねない, 死ねる, 死ねます
  "うざい",
  "ファック",
];

const PATTERNS = [
  ...WORDS.map((w) => new RegExp(`\\b${w}\\b`, "iu")),
  ...JA_PATTERNS.map((p) => new RegExp(p, "iu")),
];

export function containsInappropriateContent(text: string): boolean {
  return PATTERNS.some((re) => re.test(text));
}
