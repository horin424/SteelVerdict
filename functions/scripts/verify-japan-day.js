/**
 * Offline verification of the game's day (02 C, "Daily reward day boundary").
 *
 * The daily reward, the X-share reward and the ad-ticket cap compared UTC
 * dates, while the app compared the phone's dates. In Japan the server's day
 * began at 9:00, so from 0:00 to 9:00 the app offered a reward the server
 * refused. Both now use the date in Japan. This checks the server's side; the
 * app's is test/date_utils_test.dart, on the same moments.
 *
 * Run: npm run verify:japanday
 */
const { japanDateString } = require("../lib/utils/japanDay");

let fail = 0;
function check(name, actual, expected) {
  if (actual === expected) {
    console.log(`  ok   ${name}`);
  } else {
    fail++;
    console.log(`  FAIL ${name} - expected ${expected}, got ${actual}`);
  }
}

console.log("\ngame day: the date in Japan\n");
check("23:59:59 in Japan is still the 13th", japanDateString(new Date("2026-10-13T14:59:59Z")), "2026-10-13");
check("0:00 in Japan is the 14th (15:00 UTC the day before)", japanDateString(new Date("2026-10-13T15:00:00Z")), "2026-10-14");
check("8:59 in Japan is the 14th, though UTC is still the 13th", japanDateString(new Date("2026-10-13T23:59:00Z")), "2026-10-14");
check("9:00 in Japan is the 14th (0:00 UTC)", japanDateString(new Date("2026-10-14T00:00:00Z")), "2026-10-14");
check("year end: 0:00 on 1 Jan in Japan", japanDateString(new Date("2026-12-31T15:00:00Z")), "2027-01-01");
check("leap day", japanDateString(new Date("2028-02-28T15:00:00Z")), "2028-02-29");

console.log("\ngame day: a claim at 23:30 and one at 0:10 in Japan are on different days\n");
const lastClaim = japanDateString(new Date("2026-10-13T14:30:00Z")); // 23:30 in Japan
const now = japanDateString(new Date("2026-10-13T15:10:00Z")); // 0:10 in Japan
check("the second claim is a new day", lastClaim === now, false);

console.log(fail === 0 ? "\nAll checks passed.\n" : `\n${fail} check(s) failed.\n`);
process.exit(fail === 0 ? 0 : 1);
