# Remote Config Guide — Steel Verdict

This guide explains how to change game settings from the Firebase console **without rebuilding the app**. No coding knowledge is required.

---

## Table of Contents

1. [How to Open Remote Config](#1-how-to-open-remote-config)
2. [Understanding the Three Config Keys](#2-understanding-the-three-config-keys)
3. [Changing Ticket Costs (including Claude)](#3-changing-ticket-costs)
4. [Switching or Adding World Settings](#4-switching-or-adding-world-settings)
5. [Editing the AI Prompt (What the Judge Says)](#5-editing-the-ai-prompt)
6. [Changing AI Models](#6-changing-ai-models)
7. [Adding a New Scenario (Enemy/Battle)](#7-adding-a-new-scenario)
8. [How Long Until Changes Appear in the App](#8-how-long-until-changes-appear)
9. [If Something Goes Wrong](#9-if-something-goes-wrong)
10. [Quick Reference: Copy-Paste Templates](#10-quick-reference-templates)

---

## 1. How to Open Remote Config

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select the project **steelverdict-81c34**
3. In the left menu, click **Run** (or **Engage**) then **Remote Config**
4. You will see a list of parameters (keys). The three main ones are:
   - `game_prompts`
   - `game_scenarios`
   - `system_config`

To edit one:
1. Click on the parameter name
2. Click the pencil icon or "Edit" next to the default value
3. Make your changes in the text box
4. Click **Save**
5. Click **Publish changes** (top right blue button)

**Important:** Always click "Publish changes" after saving. If you only save without publishing, the app will not see your changes.

---

## 2. Understanding the Three Config Keys

Think of Remote Config as three filing cabinets:

| Key | What's Inside | When to Edit |
|-----|--------------|--------------|
| `game_prompts` | World settings, AI instructions per mode, fallback prompt | You want to change the world's flavor, add a new world, or change how the AI judges battles |
| `game_scenarios` | List of battles (enemies, descriptions, difficulty) | You want to add/remove/edit battle scenarios |
| `system_config` | Ticket prices, AI model versions, developer accounts | You want to change how much things cost or switch AI models |

Each key contains JSON — structured text that looks like `{ "key": "value" }`. The guide below shows exactly what to change in each.

---

## 3. Changing Ticket Costs

**Where:** `system_config` parameter

Inside `system_config`, find the `ticket_costs` section. It looks like this:

```json
{
  "ticket_costs": {
    "normal": 1,
    "tabletop": 2,
    "epic": 3,
    "boss": 5,
    "practice": 0,
    "pvp": 1,
    "claude": 3
  }
}
```

### What Each Key Means

| Key | Meaning | Current Value |
|-----|---------|---------------|
| `normal` | Cost for a Normal mode battle (Gemini) | 1 ticket |
| `tabletop` | Cost for Tabletop mode | 2 tickets |
| `epic` | Cost for Epic mode | 3 tickets |
| `boss` | Cost for Boss battle | 5 tickets |
| `practice` | Cost for Practice mode | 0 (free) |
| `pvp` | Cost for PvP battle | 1 ticket |
| **`claude`** | **Cost when Claude AI is selected (any mode)** | **3 tickets** |

### Example: Make Claude cost 5 tickets

Change:
```json
"claude": 3
```
To:
```json
"claude": 5
```

### How Claude Cost Works

When a player selects Claude as their AI model, the app shows the `claude` cost instead of the mode cost. For example:
- Normal mode + Gemini = 1 ticket
- Normal mode + Claude = 3 tickets (the `claude` value)
- Epic mode + Gemini = 3 tickets
- Epic mode + Claude = 3 tickets (still the `claude` value)

The `claude` cost **replaces** the mode cost entirely. It does not add to it.

---

## 4. Switching or Adding World Settings

**Where:** `game_prompts` parameter

Inside `game_prompts`, the `worldviews` section defines the world settings. Currently there is one world: `1830_fantasy`.

### Current Structure

```json
{
  "worldviews": {
    "1830_fantasy": {
      "common_judgment": "You are a strict military battle judge in a fantasy world set around 1830...",
      "worldview_description": "An early 19th century world where magic and gunpowder coexist...",
      "stats": ["strength", "intellect", "skill", "magic", "art", "life"],
      "stat_descriptions": {
        "strength": { "en": "Raw physical power", "ja": "生の肉体的な力" }
      }
    }
  }
}
```

### What Each Field Does

| Field | What It Does | Example |
|-------|-------------|---------|
| `common_judgment` | The **rules** the AI follows when judging battles. This is the most important field — it tells the AI how to behave. | "You are a strict judge..." |
| `worldview_description` | The **flavor text** that sets the scene. Describes the era, technology, magic level, etc. | "A world where magic and gunpowder coexist..." |
| `stats` | The list of stats players allocate points into | `["strength", "intellect", "skill", "magic", "art", "life"]` |
| `stat_descriptions` | Explanation of each stat (shown to players), in English and Japanese | `"strength": { "en": "...", "ja": "..." }` |

### Quick Test: Just Change the Description

If you only want to test a different world feel, the simplest approach is to edit **`worldview_description`** in the existing `1830_fantasy` entry. This changes what the AI "sees" as the world setting without touching anything else.

For example, change:
```
"worldview_description": "An early 19th century world where magic and gunpowder coexist."
```
To:
```
"worldview_description": "A futuristic cyberpunk world where hackers wage digital warfare."
```

The AI will now judge battles in a cyberpunk context. No app rebuild needed.

### Adding a Second World (Dropdown Appears Automatically)

To add a new world that players can choose from a dropdown:

1. Open `game_prompts` in Remote Config
2. Add a new entry inside `worldviews` with a unique key:

```json
{
  "worldviews": {
    "1830_fantasy": {
      "title": "1830 Fantasy World",
      "titleJa": "1830年 ファンタジーワールド",
      "common_judgment": "You are a strict military battle judge in a fantasy world set around 1830...",
      "worldview_description": "An early 19th century world where magic and gunpowder coexist...",
      "stats": ["strength", "intellect", "skill", "magic", "art", "life"],
      "stat_descriptions": {
        "strength": { "en": "Raw physical power", "ja": "生の肉体的な力" },
        "intellect": { "en": "Strategic thinking", "ja": "戦略的思考" },
        "skill": { "en": "Combat technique", "ja": "戦闘技術" },
        "magic": { "en": "Magical power", "ja": "魔力" },
        "art": { "en": "Engineering skill", "ja": "工学技術" },
        "life": { "en": "Endurance and morale", "ja": "持久力と士気" }
      }
    },
    "cyberpunk_2099": {
      "title": "Cyberpunk 2099",
      "titleJa": "サイバーパンク2099",
      "common_judgment": "You are a cold, calculating battle arbiter in a dystopian cyberpunk world. Judge hacking strategies, drone warfare, and cybernetic combat. Always end with VICTORY, DEFEAT, or STALEMATE.",
      "worldview_description": "Year 2099. Megacorporations wage shadow wars using AI, drones, and cyber-enhanced soldiers. The battlefield is both physical and digital.",
      "stats": ["strength", "intellect", "skill", "magic", "art", "life"],
      "stat_descriptions": {
        "strength": { "en": "Physical combat power (cybernetic)", "ja": "肉体戦闘力（サイバネティック）" },
        "intellect": { "en": "Hacking and strategic AI", "ja": "ハッキングと戦略AI" },
        "skill": { "en": "Precision and reflexes", "ja": "精度と反射神経" },
        "magic": { "en": "Quantum tech / nano-magic", "ja": "量子技術/ナノ魔法" },
        "art": { "en": "Drone engineering", "ja": "ドローン工学" },
        "life": { "en": "System integrity and resilience", "ja": "システム整合性と耐久性" }
      }
    }
  }
}
```

**What happens in the app:** A dropdown labeled "World Setting" appears at the top of the game mode screen. Players can switch between "1830 Fantasy World" and "Cyberpunk 2099" before starting a battle.

**Important:** Keep the same stat keys (`strength`, `intellect`, etc.) across all worldviews. The stat keys must match because players' race stats are stored with these keys. Only the descriptions and AI prompt change — not the underlying stat structure.

---

## 5. Editing the AI Prompt (What the Judge Says)

The AI prompt is assembled from **four pieces** in this order:

```
1. common_judgment     ← General rules (from worldview)
2. worldview_description ← World flavor text (from worldview)
3. mode_addons         ← Mode-specific instructions (see below)
4. commander_definition ← Enemy description (from scenario)
```

### Mode Addons

**Where:** `game_prompts` > `mode_addons`

These control how the AI formats its response depending on the game mode:

```json
{
  "mode_addons": {
    "practice": "Output a battle report of 50 characters or less.",
    "normal": "Write a detailed battle report of 1000 characters or more.",
    "tabletop": "Simulate this battle 10 times. Output only the win rate.",
    "epic": "Write a rich, epic narrative of 1500 characters or more.",
    "boss": "Write a detailed report. The player faces a powerful boss.",
    "history_puzzle": "Evaluate strategy strictly. Write 500+ characters.",
    "pvp": "Judge fairly. Write 40 char report, then state the winner."
  }
}
```

### Example: Make Normal Mode Responses Shorter

Change:
```json
"normal": "Write a detailed battle report of 1000 characters or more."
```
To:
```json
"normal": "Write a concise battle report of 300 characters or less."
```

### The Full Prompt the AI Sees (Example)

For a Normal mode battle in the 1830 Fantasy world against scenario_001:

```
[System Message]
You are a strict military battle judge in a fantasy world set around 1830...

An early 19th century world where magic and gunpowder coexist...

Write a detailed battle report of 1000 characters or more.

A disorganized bandit force threatening the western border...

[User Message]
Race: Dragon Knights
Stats: strength: 8, intellect: 5, skill: 7, magic: 3, art: 4, life: 3

Strategy: I will flank from the east using cavalry...
```

---

## 6. Changing AI Models

**Where:** `system_config` > `model_config`

```json
{
  "model_config": {
    "gemini_flash": "gemini-2.5-flash",
    "gemini_flash_lite": "gemini-2.5-flash-lite",
    "claude": "claude-haiku-4-5-20251001"
  }
}
```

| Key | Used For | Default |
|-----|----------|---------|
| `gemini_flash` | Normal / Epic / Boss modes (when Gemini selected) | gemini-2.5-flash |
| `gemini_flash_lite` | Practice / Tabletop / History Puzzle modes | gemini-2.5-flash-lite |
| `claude` | All modes when Claude is selected | claude-haiku-4-5-20251001 |

To upgrade Claude to a newer model, just change the value:
```json
"claude": "claude-sonnet-4-6"
```

---

## 7. Adding a New Scenario (Enemy/Battle)

**Where:** `game_scenarios` > `scenarios`

Each scenario represents a battle the player can choose:

```json
{
  "scenarios": {
    "scenario_004": {
      "scenarioId": "scenario_004",
      "title": "The Frozen Pass",
      "titleJa": "凍りの峠",
      "enemyName": "Ice Wyrm Legion",
      "enemyNameJa": "氷竜軍団",
      "difficulty": 4,
      "isFree": false,
      "battleType": "standard",
      "worldviewKey": "1830_fantasy",
      "commander_definition": "An elite force of frost mages and ice wyrm riders. Commander Yselda wields ancient ice magic and fights with ruthless precision.",
      "commanderDefinitionJa": "霜の魔術師と氷竜騎兵の精鋭部隊。指揮官イゼルダは古代の氷魔法を操り、冷酷な精度で戦う。"
    }
  }
}
```

| Field | Required | What It Does |
|-------|----------|-------------|
| `scenarioId` | Yes | Unique ID, must match the key (e.g. `scenario_004`) |
| `title` | Yes | English name shown in the scenario list |
| `titleJa` | Yes | Japanese name |
| `enemyName` | Yes | English enemy name |
| `enemyNameJa` | Yes | Japanese enemy name |
| `difficulty` | Yes | 1-5 star difficulty rating |
| `isFree` | Yes | `true` = no ticket needed, `false` = costs tickets |
| `battleType` | Yes | `"standard"`, `"boss"`, or `"history"` |
| `worldviewKey` | Yes | Which world this scenario belongs to (e.g. `"1830_fantasy"`) |
| `commander_definition` | Yes | English description of the enemy — this is sent to the AI as part of the prompt |
| `commanderDefinitionJa` | No | Japanese description (optional, falls back to English) |

---

## 8. How Long Until Changes Appear

| Where | Delay |
|-------|-------|
| **App (already open)** | Up to **1 hour** (the app checks for updates once per hour) |
| **App (freshly opened)** | Immediately on next launch |
| **Backend (Cloud Functions)** | Up to **5 minutes** (server caches for 5 min) |

To force-update during testing: close the app completely and reopen it.

---

## 9. If Something Goes Wrong

### The App Shows Default Values Instead of My Changes

- Did you click **"Publish changes"** in Firebase Console? (Save alone is not enough)
- Is the JSON valid? Even one missing comma or bracket will cause the app to fall back to defaults.
- Try pasting your JSON into [jsonlint.com](https://jsonlint.com) to check for errors.

### Common JSON Mistakes

```
Wrong:  "title": "Hello",     ← trailing comma before closing }
                          }

Wrong:  "title": Hello         ← missing quotes around value

Wrong:  "stats": [a, b, c]    ← missing quotes around array items

Right:  "title": "Hello"
Right:  "stats": ["a", "b", "c"]
```

### The AI Ignores My Prompt Changes

- The server caches prompts for 5 minutes. Wait and try again.
- Check that you edited the correct worldview key (e.g. `1830_fantasy`).
- Make sure your `common_judgment` still ends with instructions about VICTORY/DEFEAT/STALEMATE — the AI needs this to determine the battle outcome.

### Players Don't See the Worldview Dropdown

The dropdown only appears when there are **2 or more** worldviews in Remote Config. If you only have one worldview, it shows as a label instead. Add a second worldview entry to activate the dropdown.

---

## 10. Quick Reference Templates

### Minimal New Worldview (Copy-Paste)

```json
"my_new_world": {
  "title": "My New World",
  "titleJa": "新しい世界",
  "common_judgment": "You are a battle judge in [describe world]. Evaluate strategy based on stats. Always end with VICTORY, DEFEAT, or STALEMATE.",
  "worldview_description": "[Describe the era, technology, magic level, and atmosphere]",
  "stats": ["strength", "intellect", "skill", "magic", "art", "life"],
  "stat_descriptions": {
    "strength": { "en": "Physical power", "ja": "肉体的な力" },
    "intellect": { "en": "Strategic thinking", "ja": "戦略的思考" },
    "skill": { "en": "Combat technique", "ja": "戦闘技術" },
    "magic": { "en": "Magical power", "ja": "魔力" },
    "art": { "en": "Engineering", "ja": "工学" },
    "life": { "en": "Endurance", "ja": "持久力" }
  }
}
```

### Minimal New Scenario (Copy-Paste)

```json
"scenario_new": {
  "scenarioId": "scenario_new",
  "title": "Battle Name",
  "titleJa": "バトル名",
  "enemyName": "Enemy Name",
  "enemyNameJa": "敵名",
  "difficulty": 3,
  "isFree": false,
  "battleType": "standard",
  "worldviewKey": "1830_fantasy",
  "commander_definition": "Describe the enemy commander and their forces here. This text is sent directly to the AI."
}
```

### Full system_config (Copy-Paste)

```json
{
  "ticket_costs": {
    "normal": 1,
    "tabletop": 2,
    "epic": 3,
    "boss": 5,
    "practice": 0,
    "pvp": 1,
    "claude": 3
  },
  "model_config": {
    "gemini_flash": "gemini-2.5-flash",
    "gemini_flash_lite": "gemini-2.5-flash-lite",
    "claude": "claude-haiku-4-5-20251001"
  },
  "dev_uids": []
}
```
