/**
 * Offline verification of the word filter (02 C, "Content filter").
 *
 * The server had its own list, matched Japanese as plain substrings, and
 * differed from the app's. So it refused text the app had accepted, and only
 * after the battle was sent: バカンス contains バカ, 死ねば contains 死ね. The two
 * lists are now one. This checks the server's filter on the same sentences as
 * the app's test (test/content_filter_test.dart), and that both lists are
 * still identical.
 *
 * Run: npm run verify:filter
 */
const fs = require("fs");
const path = require("path");
const { containsInappropriateContent, WORDS, JA_PATTERNS } = require("../lib/utils/contentFilter");

let fail = 0;
function check(name, actual, expected) {
  if (JSON.stringify(actual) === JSON.stringify(expected)) {
    console.log(`  ok   ${name}`);
  } else {
    fail++;
    console.log(`  FAIL ${name} - expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

const allowed = [
  "I will assault the left flank at dawn.",
  "Mass my troops and pass through the valley.",
  "Fire from the cockpit at close range.",
  "March the army through Wessex and Essex.",
  "Kill the enemy commander in the first charge.",
  "Advance across the grass toward the ridge.",
  "敵を殺すつもりで突撃する。",
  "攻撃するばかりで守りが薄い。",
  "ばからしいほど単純な作戦だ。",
  "バカンスの季節に奇襲する。",
  "アホウドリの群れを目印に進む。",
  "くそまじめな将軍が守る砦。",
  "ここで死ねば本望だ。",
  "彼らは死ねない兵士だ。",
];
const blocked = [
  "fuck this game",
  "you are a bitch",
  "what a retard",
  "you asshole",
  "ばか野郎",
  "このアホが",
  "ちくしょう",
  "バカめ",
  "死ね",
  "うざいな",
  "ファックだ",
];

console.log("\nword filter: ordinary text passes\n");
for (const t of allowed) check(`allows "${t}"`, containsInappropriateContent(t), false);

console.log("\nword filter: abuse is still refused\n");
for (const t of blocked) check(`refuses "${t}"`, containsInappropriateContent(t), true);

console.log("\nthe app and the server use the same lists\n");
const dart = fs.readFileSync(
  path.join(__dirname, "../../lib/core/utils/content_filter.dart"), "utf8");
function dartList(name) {
  const block = dart.match(new RegExp(`${name} = \\[([\\s\\S]*?)\\];`));
  if (!block) return null;
  // Each entry is a quoted string; comments after it are not.
  return [...block[1].matchAll(/^\s*'([^']*)',/gm)].map((m) => m[1]);
}
const sorted = (a) => [...(a || [])].sort();
check("whole words: app = server", sorted(dartList("_wordBlacklist")), sorted(WORDS));
check("Japanese patterns: app = server", sorted(dartList("_jaPatterns")), sorted(JA_PATTERNS));

console.log(fail ? `\n${fail} check(s) FAILED\n` : "\nall checks passed\n");
process.exit(fail ? 1 : 0);
