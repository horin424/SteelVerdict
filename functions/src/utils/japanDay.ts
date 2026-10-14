/**
 * The game's day: the date in Japan (UTC+9, no daylight saving). The daily
 * reward, the X-share reward and the ad-ticket cap all reset at midnight Japan
 * time, the same day as the app's (GameDateUtils.japanDate in
 * lib/core/utils/date_utils.dart). These used the UTC date while the app used
 * the phone's, so from 0:00 to 9:00 in Japan the app offered a reward that the
 * server refused.
 */
const JAPAN_OFFSET_MS = 9 * 60 * 60 * 1000;

/** The date in Japan of the given moment, as "YYYY-MM-DD". */
export function japanDateString(date: Date): string {
  return new Date(date.getTime() + JAPAN_OFFSET_MS).toISOString().substring(0, 10);
}
