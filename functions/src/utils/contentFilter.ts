// Words refused in strategies and race names. The app has its own list
// (lib/core/utils/content_filter.dart).

const BLACKLIST_EN = [
  "fuck", "shit", "bitch", "nigger", "nigga", "faggot", "retard",
  "kike", "spic", "chink", "whore", "cunt", "bastard", "asshole",
];

const BLACKLIST_JA = ["バカ", "死ね", "クソ", "うざい", "ファック"];

const EN_PATTERNS = BLACKLIST_EN.map(
  (w) => new RegExp(`\\b${w}\\b`, "iu"),
);

export function containsInappropriateContent(text: string): boolean {
  if (EN_PATTERNS.some((re) => re.test(text))) return true;
  return BLACKLIST_JA.some((word) => text.includes(word));
}
