# Strategy Game — AI Text Strategy Simulation

A text-based strategy simulation game powered by Gemini and Claude AI.
Players write military strategies and the AI evaluates them to determine battle outcomes.

**Firebase Project:** `steelverdict-81c34`
**Platforms:** Android + iOS

---

## Table of Contents

1. [Project Setup](#1-project-setup)
2. [Firebase Setup](#2-firebase-setup)
3. [AdMob Setup](#3-admob-setup)
4. [Keys & Secrets Required](#4-keys--secrets-required)
5. [Firebase Remote Config](#5-firebase-remote-config)
6. [In-App Purchases Setup](#6-in-app-purchases-setup)
7. [Android Release Signing](#7-android-release-signing)
8. [Deploy Cloud Functions](#8-deploy-cloud-functions)
9. [Pre-Release Checklist](#9-pre-release-checklist)

---

## 1. Project Setup

```bash
flutter pub get
cd functions && npm install
```

---

## 2. Firebase Setup

### 2.1 Download Config Files

Go to **Firebase Console → steelverdict-81c34 → Project Settings → Your Apps**

| File | Destination |
|------|-------------|
| `google-services.json` | `android/app/google-services.json` |
| `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` |

### 2.2 Enable Firebase Services

In **Firebase Console**, enable these one by one:

| Service | Where | Notes |
|---------|-------|-------|
| Authentication | Build → Authentication → Get started | Enable **Anonymous** and **Email/Password** sign-in |
| Firestore | Build → Firestore Database → Create database | Use **Production mode** |
| Cloud Functions | Build → Functions | Auto-enabled on deploy |
| Remote Config | Build → Remote Config | Select **Client** tab |
| Analytics | Project Overview → Analytics | Link to Google Analytics |

### 2.3 Enable Required Google Cloud APIs

Go to **Google Cloud Console → steelverdict-81c34 → APIs & Services → Enable APIs**

Enable these:
- Cloud Functions API
- Cloud Run API
- Eventarc API
- Secret Manager API
- Cloud Build API

### 2.4 Required IAM Roles

Go to **Google Cloud Console → IAM & Admin → IAM**

Grant these roles via **+ GRANT ACCESS**:

| Principal | Role |
|-----------|------|
| `service-60492504266@gcp-sa-pubsub.iam.gserviceaccount.com` | Service Account Token Creator |
| `60492504266-compute@developer.gserviceaccount.com` | Cloud Run Invoker |
| `60492504266-compute@developer.gserviceaccount.com` | Eventarc Event Receiver |
| `service-60492504266@gcp-sa-eventarc.iam.gserviceaccount.com` | Eventarc Service Agent |
| Your deploy account email | Cloud Functions Admin |
| Your deploy account email | Secret Manager Admin |

---

## 3. AdMob Setup

### 3.1 Create AdMob Account

1. Go to **admob.google.com**
2. Sign in with the **same Google account** as your Firebase project
3. Fill in country, timezone, billing info
4. Click **"Start using AdMob"**

### 3.2 Add Your App to AdMob

1. Left sidebar → **Apps → Add app**
2. **Is app published?** → Select **No** (for new apps)
3. Select platform → **Android** first, then repeat for **iOS**
4. Enter app name → `strategy_game`
5. Click **Add**
6. Copy the **App ID** — you will need it

**App ID format:** `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`

### 3.3 Create Ad Units

Inside your app in AdMob → **Ad units → Add ad unit**

Create these 3 ad units for **each platform** (Android + iOS):

| Ad Unit Name | Type | Used For |
|--------------|------|---------|
| `banner` | Banner | General display |
| `interstitial` | Interstitial | Between game modes |
| `rewarded` | Rewarded | Earn tickets by watching |

Each ad unit gives you an ID like:
`ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`

Save all 6 IDs (3 for Android, 3 for iOS).

### 3.4 Add App ID to Android

Open `android/app/src/main/AndroidManifest.xml` and add inside `<application>`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

### 3.5 Add App ID to iOS

Open `ios/Runner/Info.plist` and add:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

### 3.6 Add Ad Unit IDs to Firebase Remote Config

After creating ad units, add these keys to **Firebase Remote Config** (Client):

| Key | Value |
|-----|-------|
| `banner_ad_unit_id` | Android banner ad unit ID |
| `interstitial_ad_unit_id` | Android interstitial ad unit ID |
| `rewarded_ad_unit_id` | Android rewarded ad unit ID |
| `banner_ad_unit_id_ios` | iOS banner ad unit ID |
| `interstitial_ad_unit_id_ios` | iOS interstitial ad unit ID |
| `rewarded_ad_unit_id_ios` | iOS rewarded ad unit ID |

### 3.7 Link AdMob to Firebase (Optional but recommended)

Requires **Owner** role on Firebase project.

1. Go to **Firebase Console → Project Settings → Integrations → AdMob**
2. Click **Link** and select your AdMob account
3. This enables AdMob analytics in Firebase dashboard

### 3.8 Test Ad Unit IDs (Development Only)

Use these during development — they will never charge real users:

| Type | Test ID |
|------|---------|
| Banner | `ca-app-pub-3940256099942544/6300978111` |
| Interstitial | `ca-app-pub-3940256099942544/1033173712` |
| Rewarded | `ca-app-pub-3940256099942544/5224354917` |

> The app currently uses these test IDs. Replace with real IDs in Remote Config before release.

---

## 4. Keys & Secrets Required

### 4.1 API Keys Needed

| Key | Where to Get | How to Set |
|-----|-------------|-----------|
| `GEMINI_API_KEY` | Google AI Studio → aistudio.google.com → Get API Key | `firebase functions:secrets:set GEMINI_API_KEY` |
| `CLAUDE_API_KEY` | Anthropic Console → console.anthropic.com → API Keys | `firebase functions:secrets:set CLAUDE_API_KEY` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT` | Google Play Console → Setup → API access → Service account JSON | `firebase functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT` |
| `APPLE_SHARED_SECRET` | App Store Connect → Apps → your app → In-App Purchases → Shared Secret | `firebase functions:secrets:set APPLE_SHARED_SECRET` |

### 4.2 How to Get Each Key

**GEMINI_API_KEY:**
1. Go to aistudio.google.com
2. Click **"Get API key"**
3. Select project `steelverdict-81c34`
4. Copy the key

**CLAUDE_API_KEY:**
1. Go to console.anthropic.com
2. Sign up / log in
3. Go to **API Keys → Create Key**
4. Copy the key

**GOOGLE_PLAY_SERVICE_ACCOUNT:**
1. Go to **Google Play Console → Setup → API access**
2. Link to Google Cloud project `steelverdict-81c34`
3. Click **"Create new service account"**
4. Go to Google Cloud Console → find the service account → **Keys → Add Key → JSON**
5. Download the JSON file
6. Set secret as the full JSON string:
   ```bash
   firebase functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT < service-account.json
   ```

**APPLE_SHARED_SECRET:**
1. Go to **App Store Connect → Apps → your app**
2. Left sidebar → **In-App Purchases → Manage**
3. Click **"App-Specific Shared Secret"**
4. Generate and copy the secret

### 4.3 Set All Secrets

Run these commands one by one in your terminal from the project root:

```bash
firebase functions:secrets:set GEMINI_API_KEY
firebase functions:secrets:set CLAUDE_API_KEY
firebase functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT
firebase functions:secrets:set APPLE_SHARED_SECRET
```

Each command will prompt you to paste the value.

---

## 5. Firebase Remote Config

Go to **Firebase Console → Remote Config → Configuration (Client tab)**

Click **"Add parameter"** for each key below, then click **"Publish changes"** when done.

### 5.1 Worldviews (JSON)

**Key:** `worldviews`
**Type:** JSON

```json
{
  "1830_fantasy": {
    "title": "1830s Fantasy",
    "stats": ["Wisdom", "Technology", "Magic", "Art", "Life", "Strength"],
    "stat_descriptions": {
      "Art": "Engineer, fortification, and crafting abilities (not singing or drawing)"
    },
    "common_judgment": "YOUR_JUDGMENT_PROMPT_HERE",
    "worldview_description": "The assumed time period is around 1830."
  }
}
```

### 5.2 Scenarios (JSON)

**Key:** `scenarios`
**Type:** JSON

```json
{
  "001_waterloo": {
    "worldview": "1830_fantasy",
    "title": "Waterloo",
    "difficulty": "Hard",
    "is_free": true,
    "enemy_name": "Duke of Wellington",
    "enemy_stats": {
      "wisdom": 9,
      "technology": 7,
      "magic": 0,
      "arts": 8,
      "vitality": 7,
      "strength": 6
    },
    "commander_definition": "Duke of Wellington. Cautious and defensive, makes maximum use of terrain. Prioritize rationality over emotion. Respond dynamically to the player strategy. No rock-paper-scissors after the fact."
  }
}
```

### 5.3 Mode Addons (JSON)

**Key:** `mode_addons`
**Type:** JSON

```json
{
  "enshu": "Output only the result in battle report format of 50 characters or less.",
  "kikjo": "If you simulate this battle 10 times, what is the estimated win rate in 20 characters or less?",
  "history_puzzle_base": "Before making a decision, refer to the enemy general character definition and respond dynamically. No rock-paper-scissors after the fact."
}
```

### 5.4 Ad Unit IDs (String)

Add each as a separate **String** parameter:

| Key | Value |
|-----|-------|
| `banner_ad_unit_id` | Your Android banner ID |
| `interstitial_ad_unit_id` | Your Android interstitial ID |
| `rewarded_ad_unit_id` | Your Android rewarded ID |

### 5.5 Ticket Costs (JSON) — Optional Override

**Key:** `ticketCosts`
**Type:** JSON

```json
{
  "gemini": 1,
  "claude": 3,
  "warHistory": 1,
  "pvpDetail": 1
}
```

> After adding all parameters, click **"Publish changes"** — values won't be live until published.

---

## 6. In-App Purchases Setup

### 6.1 Product IDs

These product IDs must be created in both stores exactly as shown:

| Product | Type | Price | ID |
|---------|------|-------|----|
| Sub 500 | Subscription | ¥500/month | `strategy_game_sub_500_monthly` |
| Sub 1000 | Subscription | ¥1000/month | `strategy_game_sub_1000_monthly` |
| Sub 3000 | Subscription | ¥3000/month | `strategy_game_sub_3000_monthly` |
| Tickets 10 | Consumable | ¥100 | `strategy_game_tickets_10` |
| Tickets 30 | Consumable | ¥250 | `strategy_game_tickets_30` |

### 6.2 Google Play Console

1. Go to **Google Play Console → your app → Monetize**
2. **Subscriptions** → Create each subscription product
3. **In-app products** → Create each consumable product
4. Set prices and activate each product

### 6.3 App Store Connect

1. Go to **App Store Connect → your app → In-App Purchases**
2. Create each product with matching IDs
3. Submit for review with your app

---

## 7. Android Release Signing

### 7.1 Create a Keystore

Run this command once and save the keystore file safely:

```bash
keytool -genkey -v -keystore android/app/release.keystore \
  -alias strategy_game \
  -keyalg RSA -keysize 2048 -validity 10000
```

> **IMPORTANT:** Never lose this keystore file. You cannot update your app without it.

### 7.2 Create key.properties

Create file `android/key.properties` (this file is gitignored):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=strategy_game
storeFile=../app/release.keystore
```

### 7.3 Update build.gradle.kts

In `android/app/build.gradle.kts`, replace the release signing config:

```kotlin
val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

signingConfigs {
    create("release") {
        keyAlias = keyProperties["keyAlias"] as String
        keyPassword = keyProperties["keyPassword"] as String
        storeFile = file(keyProperties["storeFile"] as String)
        storePassword = keyProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

---

## 8. Deploy Cloud Functions

```bash
# Set secrets first (see Section 4)
firebase functions:secrets:set GEMINI_API_KEY
firebase functions:secrets:set CLAUDE_API_KEY
firebase functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT
firebase functions:secrets:set APPLE_SHARED_SECRET

# Deploy
firebase deploy --only functions
```

---

## 9. Pre-Release Checklist

### Configuration
- [ ] `google-services.json` in `android/app/`
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] All 4 Firebase secrets set
- [ ] Remote Config populated and published
- [ ] Real AdMob App IDs in `AndroidManifest.xml` and `Info.plist`
- [ ] Real ad unit IDs in Remote Config

### Code
- [ ] Package name changed from `com.example.strategy_game` to real name
- [ ] Privacy policy URL updated in `settings_screen.dart`
- [ ] IAP product IDs verified (client matches server)
- [ ] Android release signing configured

### Stores
- [ ] IAP products created in Google Play Console
- [ ] IAP products created in App Store Connect
- [ ] AdMob app created and ad units generated
- [ ] Privacy policy page published online

### Firebase
- [ ] Cloud Functions deployed successfully
- [ ] Firestore rules deployed
- [ ] Authentication providers enabled
- [ ] Analytics enabled
