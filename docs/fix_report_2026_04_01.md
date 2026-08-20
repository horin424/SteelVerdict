# Fix Report — 2026-04-01

## Overview

Four changes based on client feedback, all confirmed compiling with zero new errors.

---

## Fix 1: Volume Slider (BGM / SFX)

**Problem:** Sound volume was fixed at a high level. Users could only turn sound ON or OFF — no way to adjust how loud background music or sound effects are.

**What changed:**

- Settings screen now shows **two sliders** (BGM Volume, SFX Volume) when sound is turned ON.
- Each slider goes from 0 to 100.
- The chosen volume is **saved automatically** — it remembers your setting even after closing the app.
- Default values: BGM = 35%, SFX = 70% (same as before, but now adjustable).

**Files changed:**
- `lib/services/sound/sound_service.dart` — added dynamic volume support
- `lib/services/sound/sound_service_provider.dart` — loads saved volume on startup
- `lib/features/settings/settings_providers.dart` — added volume state + persistence
- `lib/features/settings/screens/settings_screen.dart` — added slider UI
- `lib/core/l10n/app_en.arb` / `app_ja.arb` — new labels

---

## Fix 2: Claude Ticket Cost Display (3 Tickets)

**Problem:** The backend correctly charged 3 tickets when Claude was selected, but the app UI always showed the cost based on game mode (e.g. "1" for Normal), not accounting for the Claude surcharge. Users had no way to know Claude costs more before starting a battle.

**What changed:**

- A new `effectiveTicketCostProvider` calculates the real cost based on **both** the selected game mode AND the selected AI model.
- When Claude is selected, the ticket cost badge and the Start Battle button now show **3** (or whatever the RC `claude` cost is set to).
- When Gemini is selected, it shows the normal mode-based cost (e.g. 1 for Normal, 2 for Tabletop).
- Practice mode always shows FREE regardless of model.
- The `claude` cost key is now included in the default ticket costs on both Flutter and backend sides.

**Files changed:**
- `lib/features/game_mode_selection/game_mode_providers.dart` — new `effectiveTicketCostProvider`
- `lib/features/game_mode_selection/screens/game_mode_selection_screen.dart` — uses effective cost
- `lib/features/battle/battle_providers.dart` — ticket check uses effective cost
- `lib/models/game_config_model.dart` — defaults include `claude: 3`
- `lib/services/remote_config/firebase_remote_config_service.dart` — RC default includes `claude: 3`

---

## Fix 3: World Setting Selector

**Problem:** The worldview (world setting) was hardcoded to `1830_fantasy`. Even though the backend and data model supported multiple worldviews, there was no way to switch between them in the app.

**What changed:**

- A **worldview dropdown** now appears on the game mode selection screen.
  - If only one worldview exists in Remote Config, it shows as a simple label (no dropdown).
  - If multiple worldviews exist, a dropdown lets you pick which world to use.
- The selected worldview key is sent to the backend in the battle request.
- The dropdown shows the **localized title** (English or Japanese depending on app language).

**How to add a new world setting:**
Add a new entry to the `worldviews` key in Firebase Remote Config. See the separate guide (`docs/remote_config_guide.md`) for step-by-step instructions.

**Files changed:**
- `lib/features/game_mode_selection/game_mode_providers.dart` — new providers for worldview selection
- `lib/features/game_mode_selection/screens/game_mode_selection_screen.dart` — worldview dropdown UI
- `lib/features/battle/battle_providers.dart` — passes selected worldview to battle request

---

## Fix 4: Model Selector Moved to Top as Dropdown

**Problem:** The AI model selector (Gemini/Claude toggle) was hidden below the game mode cards and only appeared when "Normal" mode was selected. This made it hard to discover and use.

**What changed:**

- The old toggle-button style model selector is removed.
- A new **top info bar** sits above the mode cards, containing:
  - **AI Model dropdown** (Gemini / Claude) — always visible, disabled only for Practice mode
  - **Ticket cost badge** — updates instantly when you switch models or modes
  - **World setting dropdown** (when multiple worldviews are available)
- The dropdown style matches the dark UI theme with gold accents.

**Files changed:**
- `lib/features/game_mode_selection/screens/game_mode_selection_screen.dart` — complete rebuild of top section
- `lib/features/game_mode_selection/widgets/model_selector_row.dart` — no longer used (can be deleted later)

---

## Localization

New strings added to both `app_en.arb` and `app_ja.arb`:

| Key | EN | JA |
|-----|----|----|
| `settingsBgmVolume` | BGM Volume | BGM音量 |
| `settingsSfxVolume` | SFX Volume | 効果音音量 |
| `gameModeModelSelect` | AI Model | AIモデル |
| `gameModeTicketInfo` | {cost} tickets | {cost}チケット |
| `gameModeWorldview` | World Setting | 世界設定 |
| `gameModeWorldviewDesc` | Choose the world setting for your battle | バトルの世界設定を選択してください |
