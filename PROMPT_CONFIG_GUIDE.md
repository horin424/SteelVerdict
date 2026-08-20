# Prompt Configuration Guide

This guide explains how to configure the AI battle prompts via Firebase Remote Config, including how to fix Victory/Draw/Defeat display and language output issues.

---

## Overview

The battle AI assembles its system prompt from **4 building blocks**, in this order:

```
1. common_judgment          ← Global rules & outcome format
2. worldview_description    ← World setting / lore
3. mode_addons[gameMode]    ← Per-mode length/style instructions
4. commander_definition     ← Per-scenario enemy info
```

All of these live in the `game_prompts` Remote Config key (JSON).

---

## Remote Config Keys

Go to **Firebase Console → Remote Config** and edit the value of each key.

### Key 1: `game_prompts`

Controls all AI prompt content.

```json
{
  "worldviews": {
    "1830_fantasy": {
      "common_judgment": "...",
      "worldview_description": "..."
    }
  },
  "mode_addons": {
    "practice": "...",
    "normal": "...",
    "tabletop": "...",
    "epic": "...",
    "boss": "...",
    "history_puzzle": "...",
    "pvp": "..."
  },
  "fallback_prompt": "..."
}
```

### Key 2: `game_scenarios`

Controls scenario list, titles, and enemy descriptions.

```json
{
  "scenarios": {
    "scenario_id_here": {
      "title": "Scenario Title",
      "enemy_name": "Enemy Commander Name",
      "commander_definition": "Enemy description for AI context...",
      "battleType": "standard"
    }
  }
}
```

### Key 3: `system_config`

Controls ticket costs, AI model routing, and dev UIDs.

```json
{
  "ticket_costs": {
    "practice": 0,
    "normal": 1,
    "tabletop": 2,
    "epic": 3,
    "boss": 2,
    "history_puzzle": 1,
    "pvp": 1
  },
  "model_config": {
    "practice": "gemini-flash-lite",
    "normal": "gemini-flash",
    "tabletop": "gemini-flash-lite",
    "epic": "claude",
    "boss": "gemini-flash",
    "history_puzzle": "gemini-flash"
  },
  "dev_uids": ["uid-here"]
}
```

---

## Fix 1: Victory / Draw / Defeat Not Displaying

**Root cause:** The AI response must end with one of these exact words on its own line:

```
VICTORY
DEFEAT
STALEMATE
```

If the AI writes "you have won" or "draw" or something else, the client cannot parse the outcome and may show nothing or show the wrong result.

**How to fix — add this to `common_judgment`:**

```
You are a strict military battle judge in a fantasy world circa 1830.
Evaluate the player's strategy objectively based on their race stats.
Stats are: Strength, Intellect, Skill, Magic, Art, Life.

CRITICAL RULE: You MUST end every battle report with exactly one of these three words on its own line:
VICTORY
DEFEAT
STALEMATE

Do not use any other word to describe the outcome. Do not write "you won" or "draw" — use only the exact words above.
```

**Full example `common_judgment` for English output:**

```
You are a strict military battle judge in a fantasy world circa 1830.
Evaluate the player's strategy objectively based on their race stats.
Stats: Strength, Intellect, Skill, Magic, Art, Life.

Base your judgment on the actual strategy described — do not apply generic rock-paper-scissors logic.
Consider terrain, troop composition, commander skill, and the stated plan.

You MUST end every response with exactly one of these three words on its own line:
VICTORY
DEFEAT
STALEMATE
```

---

## Fix 2: Battle Report in Wrong Language

**How language is controlled:**

- If the app locale is **Japanese (JA)**, the Cloud Function automatically appends this to the system prompt:
  ```
  必ず日本語で回答してください。
  ```
- If the app locale is **English (EN)**, nothing extra is appended — the AI defaults to English.

**Problem:** If your `common_judgment` or `worldview_description` is written in Japanese, the AI may output Japanese even for English users.

**Fix:** Write all prompt content in English. The system will automatically instruct the AI to respond in Japanese for JA users. Never write Japanese in `game_prompts` — only English.

**Correct structure:**

```json
{
  "worldviews": {
    "1830_fantasy": {
      "common_judgment": "You are a military battle judge... [in English]",
      "worldview_description": "The world is set in 1830... [in English]"
    }
  }
}
```

---

## Fix 3: Mode-Specific Output Length

Each game mode has a `mode_addons` entry that controls report length and style.

| Mode | Recommended instruction |
|------|------------------------|
| `practice` | `Write a battle summary in 50 words or less.` |
| `normal` | `Write a detailed battle report of 300 words or more.` |
| `tabletop` | `Simulate this battle 10 times. Output only: Win rate: XX%` |
| `epic` | `Write an epic narrative battle report of 500 words or more with vivid descriptions and dramatic tension.` |
| `boss` | `Write a detailed battle report of 300 words or more. The enemy is a legendary boss-tier commander.` |
| `history_puzzle` | `This is a historical scenario. Evaluate the strategy strictly. Write a battle report of 200 words or more.` |
| `pvp` | Handled separately — do not change. |

**Example `mode_addons`:**

```json
{
  "mode_addons": {
    "practice": "Write a battle summary in 50 words or less.",
    "normal": "Write a detailed battle report of 300 words or more.",
    "tabletop": "Simulate this battle 10 times. Output only the win rate as: Win rate: XX%",
    "epic": "Write an epic, cinematic battle narrative of 500 words or more with dramatic descriptions.",
    "boss": "The enemy is a legendary boss-tier commander. Write a detailed battle report of 300 words or more.",
    "history_puzzle": "This is a fixed historical scenario. Evaluate the strategy strictly and write a battle report of 200 words or more."
  }
}
```

---

## Complete Working Example

Here is a complete `game_prompts` value you can paste directly into Remote Config:

```json
{
  "worldviews": {
    "1830_fantasy": {
      "common_judgment": "You are a strict military battle judge in a fantasy world circa 1830. Evaluate the player's battle strategy objectively based on their race stats (Strength, Intellect, Skill, Magic, Art, Life). React to the actual strategy described — consider terrain, numbers, commander skill, and tactics. Do not apply generic outcomes. You MUST end every response with exactly one of these three words on its own line:\nVICTORY\nDEFEAT\nSTALEMATE",
      "worldview_description": "The setting is a dark fantasy world in the early industrial era. Gunpowder coexists with ancient magic. Commanders lead armies of varied races — humans, elves, dwarves, and stranger creatures. Battles are brutal and strategic."
    }
  },
  "mode_addons": {
    "practice": "Write a battle summary in 50 words or less.",
    "normal": "Write a detailed battle report of 300 words or more.",
    "tabletop": "Simulate this battle 10 times. Output only the win rate as a percentage, formatted exactly as: Win rate: XX%",
    "epic": "Write an epic, cinematic battle narrative of 500 words or more with dramatic descriptions and vivid detail.",
    "boss": "The enemy is a legendary boss-tier commander of overwhelming power. Write a detailed battle report of 300 words or more.",
    "history_puzzle": "This is a fixed historical scenario. Evaluate the player's strategy strictly and objectively. Write a battle report of 200 words or more."
  },
  "fallback_prompt": "You are a military battle judge. Evaluate the strategy. End with VICTORY, DEFEAT, or STALEMATE on its own line."
}
```

---

## How to Update Remote Config

1. Go to [Firebase Console](https://console.firebase.google.com) → your project → **Remote Config**
2. Find the key `game_prompts`
3. Click the pencil icon to edit the value
4. Paste the JSON above (validate with a JSON validator first)
5. Click **Save** → then click **Publish changes**
6. Changes take effect within 5 minutes (server-side RC cache TTL)

> **Note:** The Cloud Function caches Remote Config for 5 minutes. After publishing, wait up to 5 minutes before testing.

---

## How to Test and Verify Your Prompt (Step-by-Step)

This section walks you through verifying a prompt change yourself, from start to finish.

### Step 1 — Make a small, recognisable change

Before testing a full rewrite, add one unique phrase to your prompt so you can confirm the AI received it.

For example, edit `common_judgment` and add this sentence at the end:

```
Always begin your battle report with the word "CONFIRMED:" so I know this prompt is active.
```

This makes it immediately obvious whether the new prompt is live.

### Step 2 — Publish to Remote Config

1. Open [Firebase Console](https://console.firebase.google.com) → your project → **Remote Config**
2. Find **`game_prompts`**, click the pencil icon
3. Edit the JSON (add your test phrase)
4. Click **Save**, then **Publish changes** (blue button, top-right)

### Step 3 — Wait for the cache to clear

The Cloud Function caches Remote Config for **5 minutes**. You must wait before the new prompt takes effect.

- After clicking Publish, wait **5 full minutes**
- Do not test immediately — you will still see the old prompt

### Step 4 — Run a Practice battle in the app

Practice mode is the fastest way to verify — it is **free (0 tickets)** and the AI response is short (≤50 words), so you get results quickly.

1. Open the app
2. From Home, tap **PLAY**
3. Select **Standard Battle**
4. Choose any scenario
5. Select **Practice** mode
6. In the strategy text box, type anything simple, for example:
   ```
   I will attack from the front with all my forces.
   ```
7. Tap **Submit**

### Step 5 — Read the response

Check the battle report for:

| What to look for | What it means |
|-----------------|---------------|
| Your test phrase (e.g. `CONFIRMED:`) appears | New prompt is active — your edit worked |
| Report ends with `VICTORY`, `DEFEAT`, or `STALEMATE` | Outcome parsing will work correctly |
| Report is in English | Language setting is correct |
| Report is very short (Practice mode) | `mode_addons["practice"]` is working |

If you do **not** see your test phrase, the 5-minute cache has not expired yet. Wait and retry.

### Step 6 — Remove the test phrase and publish final version

Once you have confirmed the prompt is live, remove the `"CONFIRMED:"` line, restore your real prompt text, and publish again.

---

### Quick Verification Checklist

```
[ ] Edited game_prompts JSON in Remote Config
[ ] Validated JSON syntax (no missing commas or brackets)
[ ] Clicked Save → Publish changes
[ ] Waited 5 minutes
[ ] Played a Practice battle
[ ] Confirmed test phrase appears in battle report
[ ] Confirmed report ends with VICTORY / DEFEAT / STALEMATE
[ ] Removed test phrase and published final version
```

---

## Worldview Keys

The app currently uses worldview key: **`1830_fantasy`**

This is set in `submitBattle.ts` as the default:
```typescript
const worldviewKey = data.worldviewKey ?? "1830_fantasy";
```

If you want to add additional worldview settings (e.g., `sci_fi`, `ancient_japan`), add them under `worldviews` in `game_prompts` and pass the corresponding key from the scenario config.

---

## Scenario `commander_definition`

Each scenario can define the enemy commander. This text is appended last in the system prompt, giving the AI specific context about who the player is fighting.

Example:
```json
{
  "scenarios": {
    "napoleon_waterloo": {
      "title": "Battle of Waterloo",
      "enemy_name": "Napoleon Bonaparte",
      "commander_definition": "The enemy is Napoleon Bonaparte commanding the French Imperial Army at its peak. He is a tactical genius who uses rapid flanking maneuvers and artillery dominance. His forces are elite but outnumbered. He will exploit any hesitation aggressively.",
      "battleType": "standard"
    }
  }
}
```

---

## Summary Checklist

| Issue | Fix |
|-------|-----|
| No VICTORY/DEFEAT shown | Add explicit rule to `common_judgment` ending with VICTORY/DEFEAT/STALEMATE |
| Report in wrong language | Write all prompts in English; JA translation is automatic |
| Report too short/long | Adjust the matching entry in `mode_addons` |
| Wrong battle scenario info | Update `commander_definition` in `game_scenarios` |
| Changes not taking effect | Wait 5 minutes after publishing; RC cache TTL is 5 min |
