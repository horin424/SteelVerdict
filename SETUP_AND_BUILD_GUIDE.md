# Steel Verdict - Complete Setup & Build Guide

**Game Name:** Steel Verdict
**Project Name:** strategy_game
**Firebase Project:** steelverdict-81c34
**Platforms:** Android (both EN/JA flavors) + iOS
**Last Updated:** April 2026

---

## Table of Contents

1. [Prerequisites & Environment Setup](#1-prerequisites--environment-setup)
2. [Project Initialization](#2-project-initialization)
3. [Firebase Configuration](#3-firebase-configuration)
4. [Firebase Remote Config Setup](#4-firebase-remote-config-setup)
5. [Building APK for Android](#5-building-apk-for-android)
6. [Building for iOS](#6-building-for-ios)
7. [Testing Locally](#7-testing-locally)
8. [Release Preparation](#8-release-preparation)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Prerequisites & Environment Setup

### 1.1 Required Tools

You must have the following installed on your system:

| Tool | Version | Download |
|------|---------|----------|
| Flutter SDK | 3.11.1+ | https://flutter.dev/docs/get-started/install |
| Dart | 3.11.1+ | Included with Flutter |
| Android SDK | API 34+ | Android Studio or standalone |
| Java Development Kit (JDK) | 17+ | https://www.oracle.com/technetwork/java/javase/downloads/ |
| Xcode (macOS/iOS only) | 14.0+ | App Store (macOS only) |
| CocoaPods (macOS/iOS only) | 1.14+ | `sudo gem install cocoapods` |

### 1.2 Flutter Installation

```bash
# Download Flutter from: https://flutter.dev/docs/get-started/install
# Extract to your preferred location, e.g., ~/flutter or C:\flutter

# Add Flutter to PATH
# On macOS/Linux:
export PATH="$PATH:[FLUTTER_PATH]/bin"

# On Windows (PowerShell):
$env:Path += ";[FLUTTER_PATH]\bin"

# Verify installation
flutter doctor
```

**Ensure all checks pass except maybe iOS (if not building for iOS).**

### 1.3 Android Setup

```bash
# Accept Android SDK licenses
flutter doctor --android-licenses

# Verify Android tools
flutter doctor
```

Open Android Studio and verify:
- SDK location is set (Tools → SDK Manager)
- Emulator is configured (AVD Manager) — at least one virtual device

### 1.4 Clone the Repository

```bash
git clone https://github.com/[YOUR_REPO].git strategy_game
cd strategy_game
```

---

## 2. Project Initialization

### 2.1 Install Dependencies

```bash
# Get all Dart/Flutter dependencies
flutter pub get

# Generate code (localization, models, providers, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Install Firebase Cloud Functions dependencies  (optional for backend)
cd functions
npm install
cd ..
```

### 2.2 Verify Setup

```bash
flutter doctor
```

Check for:
- ✅ Flutter SDK location
- ✅ Android SDK / iOS SDK (if relevant)
- ✅ Android Studio / Xcode (if relevant)
- ✅ Connected devices or emulators

### 2.3 Check Key Files Exist

Before proceeding, ensure these files are present:

```
strategy_game/
├── pubspec.yaml                          ✅ (dependency manifest)
├── android/
│   ├── app/
│   │   ├── build.gradle.kts             ✅ (build config)
│   │   └── google-services.json         ⚠️  (Firebase Android config — see Section 3)
│   └── key.properties                   ⚠️  (release signing — see Section 8)
├── ios/
│   ├── Runner/
│   │   ├── GoogleService-Info.plist     ⚠️  (Firebase iOS config — see Section 3)
│   │   └── Info.plist
│   └── Podfile
├── lib/
│   ├── main.dart
│   ├── core/
│   └── features/
├── functions/                            (backend, optional)
└── .env                                  ⚠️  (if using — create as needed)
```

---

## 3. Firebase Configuration

### 3.1 Download Firebase Config Files

Go to **Firebase Console** → `steelverdict-81c34` → **Project Settings** → **Your apps**

#### Android Configuration

1. Select the Android app entry (or create one if missing)
2. Click **google-services.json** download button
3. Save to: `android/app/google-services.json`

#### iOS Configuration

1. Select the iOS app entry (or create one if missing)
2. Click **GoogleService-Info.plist** download button
3. Save to: `ios/Runner/GoogleService-Info.plist`

**Important:** These files contain API credentials. Never commit them to public repositories.

### 3.2 Enable Firebase Services

In **Firebase Console**, enable these services (if not already enabled):

**Go through each one:**

1. **Authentication**
   - Build → Authentication → Get Started
   - Enable: **Anonymous** and **Email/Password** sign-in methods

2. **Firestore Database**
   - Build → Firestore Database → Create Database
   - Mode: **Production**
   - Location: **nam5** (US) or your preferred region

3. **Remote Config**
   - Build → Remote Config
   - This is where you'll add game configuration (worldviews, scenarios, etc.)

4. **Cloud Functions** (optional for backend)
   - Build → Functions
   - Used for AI battle simulations and server-side logic

5. **Analytics** (optional)
   - Engage → Analytics
   - Automatically tracks user events

### 3.3 Verify Configuration

```bash
# Run app in debug mode to test Firebase connectivity
flutter run

# Once the login screen appears, try:
# 1. Anonymous login (should work)
# 2. Check Firebase Console → Authentication → Users
#    Your device should appear there
```

---

## 4. Firebase Remote Config Setup

### 4.1 What is Remote Config?

Remote Config allows you to:
- Update game worldviews, scenarios, and rules **without rebuilding the app**
- Change difficulty, prices, and AI parameters in real-time
- A/B test different game versions

### 4.2 Add Configuration Parameters

Go to **Firebase Console** → **Remote Config** → **Create configuration**

For each parameter below:
1. Click **Add parameter**
2. Enter the **Parameter key**
3. Select **Parameter type** (JSON or String)
4. Paste the **Default value**
5. Click **Save**

---

#### **Parameter 1: worldviews (JSON)**

**Key:** `worldviews`
**Type:** JSON
**Default value:**

```json
{
  "1830_fantasy": {
    "title": "1830s Fantasy",
    "commonJudgment": "You are a military judge in 1830s fantasy setting. Evaluate strategies based on terrain, troop composition, and tactical sound reasoning. No rock-paper-scissors logic.",
    "worldviewDescription": "The assumed time period is around 1830s with fantasy elements.",
    "stats": [
      "Wisdom",
      "Technology",
      "Magic",
      "Art",
      "Life",
      "Strength"
    ],
    "statDescriptions": {
      "Art": "Engineer, fortification, and crafting abilities"
    }
  },
  "naval_warfare": {
    "title": "Naval Warfare",
    "commonJudgment": "You are a naval battle judge. Evaluate strategies based on fleet positioning, wind, currents, and naval tactics.",
    "worldviewDescription": "Large-scale naval battles with period-accurate ship combat.",
    "stats": [
      "Navigation",
      "Cannonry",
      "Hull Strength",
      "Crew Morale",
      "Ship Count",
      "Leadership"
    ],
    "statDescriptions": {
      "Navigation": "Ability to control course and positioning"
    }
  }
}
```

---

#### **Parameter 2: scenarios (JSON)**

**Key:** `scenarios`
**Type:** JSON
**Default value:**

```json
{
  "001_waterloo": {
    "title": "Battle of Waterloo",
    "worldviewKey": "1830_fantasy",
    "battleType": "standard",
    "difficulty": "Hard",
    "isFree": true,
    "enemyName": "The Duke",
    "enemyStats": {
      "wisdom": 9,
      "technology": 7,
      "magic": 0,
      "art": 8,
      "life": 7,
      "strength": 6
    },
    "commanderDefinition": "Cautious and defensive commander. Prioritizes terrain control. Responds dynamically to player strategies without using rock-paper-scissors logic.",
    "description": "Face a historically inspired defensive opponent in this challenging scenario."
  },
  "002_trafalgar": {
    "title": "Battle of Trafalgar",
    "worldviewKey": "naval_warfare",
    "battleType": "standard",
    "difficulty": "Medium",
    "isFree": true,
    "enemyName": "Admiral Nelson",
    "enemyStats": {
      "navigation": 8,
      "cannonry": 9,
      "hullStrength": 7,
      "crewMorale": 8,
      "shipCount": 6,
      "leadership": 9
    },
    "commanderDefinition": "Aggressive naval commander known for bold tactics and excellent crew coordination.",
    "description": "A legendary naval encounter with a skilled opponent."
  }
}
```

---

#### **Parameter 3: modeAddons (JSON)**

**Key:** `modeAddons`
**Type:** JSON
**Default value:**

```json
{
  "standard": "Provide a battle outcome based on strategic analysis.",
  "boss": "Provide a dramatic battle conclusion. The opponent is particularly skilled.",
  "history": "Refer to the historically accurate background. Provide a 20-character win rate estimate if asked.",
  "practice": "This is a practice match. Be encouraging and educational."
}
```

---

#### **Parameter 4: ticketCosts (JSON)**

**Key:** `ticketCosts`
**Type:** JSON
**Default value:**

```json
{
  "practice": 0,
  "normal": 1,
  "tabletop": 2,
  "epic": 3,
  "warHistory": 1,
  "pvpDetail": 1
}
```

---

#### **Parameter 5: adUnitIds (JSON - Android)**

**Key:** `adUnitIds`
**Type:** JSON
**Default value:** (Use test IDs during development)

```json
{
  "android": {
    "banner": "ca-app-pub-3940256099942544/6300978111",
    "interstitial": "ca-app-pub-3940256099942544/1033173712",
    "rewarded": "ca-app-pub-3940256099942544/5224354917"
  },
  "ios": {
    "banner": "ca-app-pub-3940256099942544/6300978111",
    "interstitial": "ca-app-pub-3940256099942544/1033173712",
    "rewarded": "ca-app-pub-3940256099942544/5224354917"
  }
}
```

---

### 4.3 Publish Remote Config

After adding all parameters:

1. Scroll to top → Click **Publish changes**
2. Wait for confirmation (usually 2-5 minutes to propagate globally)
3. Parameters are now live for all app instances

---

## 5. Building APK for Android

Steel Verdict supports **two language flavors** for Android:
- **`en`** — English version
- **`ja`** — Japanese version

This means you can build two separate APKs with different app names and configurations.

### 5.1 Understanding Build Flavors

In `android/app/build.gradle.kts`, product flavors are defined:

```kotlin
productFlavors {
    create("en") {
        dimension = "lang"
        resValue("string", "app_name", "Steel Verdict")
    }
    create("ja") {
        dimension = "lang"
        resValue("string", "app_name", "スティールバーディクト")
    }
}
```

### 5.2 Install Android Release Keystore (FIRST TIME ONLY)

**⚠️ CRITICAL:** You need a keystore to sign the APK for release.

#### Option A: Use Existing Keystore (if you have one)

1. Place your keystore file in: `android/app/release.keystore`
2. Create `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=strategy_game
storeFile=../app/release.keystore
```

#### Option B: Generate New Keystore (FIRST TIME)

```bash
# Navigate to android/app directory
cd android/app

# Generate keystore (you'll be prompted for passwords)
keytool -genkey -v -keystore release.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias strategy_game \
  -dname "CN=Steel Verdict, O=Your Company, L=Your City, S=Your State, C=JP"

# Create key.properties file in android/ directory
cd ..

# Create key.properties with your passwords
cat > key.properties << EOF
storePassword=YOUR_STORE_PASSWORD_HERE
keyPassword=YOUR_KEY_PASSWORD_HERE
keyAlias=strategy_game
storeFile=../app/release.keystore
EOF

cd ..
```

**SAVE THIS KEYSTORE SECURELY!** You cannot update your app on Google Play without it.

### 5.3 Build APK — English Version

```bash
# Clean build
flutter clean
flutter pub get

# Build APK (English flavor, release mode)
flutter build apk \
  --flavor en \
  --release \
  --split-per-abi

# Output files:
# build/app/outputs/flutter-apk/app-en-release.apk (universal)
# build/app/outputs/flutter-apk/app-en-armeabi-v7a-release.apk (ARM 32-bit)
# build/app/outputs/flutter-apk/app-en-arm64-v8a-release.apk (ARM 64-bit)
```

### 5.4 Build APK — Japanese Version

```bash
# Build APK (Japanese flavor, release mode)
flutter build apk \
  --flavor ja \
  --release \
  --split-per-abi

# Output files:
# build/app/outputs/flutter-apk/app-ja-release.apk (universal)
# build/app/outputs/flutter-apk/app-ja-armeabi-v7a-release.apk (ARM 32-bit)
# build/app/outputs/flutter-apk/app-ja-arm64-v8a-release.apk (ARM 64-bit)
```

### 5.5 Verify APK

```bash
# Install on connected device/emulator (English)
flutter install --flavor en

# Or install APK directly
adb install -r build/app/outputs/flutter-apk/app-en-release.apk
```

### 5.6 Build App Bundle (For Google Play)

The App Bundle is required for Google Play Store:

```bash
# English flavor
flutter build appbundle \
  --flavor en \
  --release

# Output: build/app/outputs/bundle/enRelease/app-en-release.aab

# Japanese flavor
flutter build appbundle \
  --flavor ja \
  --release

# Output: build/app/outputs/bundle/jaRelease/app-ja-release.aab
```

---

## 6. Building for iOS

### 6.1 Prerequisites (macOS only)

iOS builds **only work on macOS**. Windows/Linux users cannot build for iOS.

```bash
# Install CocoaPods
sudo gem install cocoapods

# Update pods
cd ios
pod repo update
cd ..
```

### 6.2 Build for iOS Development

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Build for simulator (debug)
flutter run -d [SIMULATOR_ID]

# Find available simulators:
flutter emulators --launch [ID]
```

### 6.3 Build iOS App for TestFlight/App Store

```bash
# Build iOS app (release)
flutter build ios \
  --release

# Output: build/ios/iphoneos/Runner.app

# For App Store distribution:
# 1. Open Xcode: open ios/Runner.xcworkspace
# 2. Select "Any iOS Device (arm64)"
# 3. Product → Archive
# 4. Upload with Transporter (from App Store Connect)
```

---

## 7. Testing Locally

### 7.1 Debug Mode (Development)

```bash
# Run on connected device/emulator
flutter run

# With verbose logging
flutter run -v

# Hot reload during development
# Press 'r' to hot reload
# Press 'R' to hot restart (rebuilds)
```

### 7.2 Test Specific Features

#### Test Language Switching

1. Open Settings (bottom navigation)
2. Look for **Language** option
3. Switch between English and Japanese
4. Verify all text updates correctly

#### Test World Setting Selection

1. From Home, tap **PLAY** button
2. You should see **World Setting** selection screen
3. Select a world (e.g., "1830s Fantasy")
4. Verify the subtitle under PLAY button shows the selected world
5. If world dropdown not visible, Remote Config not yet populated (see Section 4)

#### Test Battle Flow

1. Tap **PLAY**
2. Select **World Setting**
3. Select **Battle Type** (Standard/Boss/History)
4. Select **Scenario** (should only show scenarios for selected world)
5. Select **Game Mode** (Practice/Normal/Tabletop/Epic)
6. Tap **Start Battle**

### 7.3 Check Firebase Connectivity

In **Firebase Console** → **Authentication** → **Users**:
- Your device should appear when you log in anonymously
- Email/password login should also work

---

## 8. Release Preparation

### 8.1 Pre-Release Checklist

Before uploading to Google Play or App Store, ensure:

**Code & Configuration:**
- [ ] Flutter version matches `pubspec.yaml` (`flutter --version`)
- [ ] All dependencies updated: `flutter pub get`
- [ ] Code generation complete: `flutter pub run build_runner build`
- [ ] No warnings in `flutter analyze`: `flutter analyze`
- [ ] Version number bumped in `pubspec.yaml` (e.g., `1.0.0` → `1.0.1`)
- [ ] No debug prints or console.logs left in code
- [ ] Privacy Policy URL set in `lib/features/settings/screens/settings_screen.dart`

**Firebase:**
- [ ] `google-services.json` in `android/app/`
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Remote Config values populated and published
- [ ] Firestore rules deployed (if needed)
- [ ] Cloud Functions deployed (if needed)

**Android:**
- [ ] Release keystore created and backed up securely
- [ ] `android/key.properties` created with correct passwords
- [ ] App name correct for each flavor (English/Japanese)
- [ ] Package name finalized: `com.example.strategy_game` → `com.steelverdict.game`
- [ ] APK/AAB builds without errors
- [ ] Tested on multiple Android versions (API 21+)

**iOS:**
- [ ] Bundle ID finalized
- [ ] App version matches Android version
- [ ] Certificates and provisioning profiles valid
- [ ] Built with Xcode for release

**Content:**
- [ ] Help Center populated with FAQ
- [ ] Privacy Policy accessible and up-to-date
- [ ] Support email verified in Settings

### 8.2 Version Management

Edit `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

### 8.3 Update Package Name (if needed)

This is a **major step** that requires code changes. Contact the developer if unsure.

```bash
# Current: com.example.strategy_game
# New: com.steelverdict.game

# This requires updates to:
# - android/app/build.gradle.kts
# - ios/Runner.xcodeproj
# - android/app/src/main/AndroidManifest.xml
```

---

## 9. Troubleshooting

### Common Issues & Solutions

#### 1. **"Flutter SDK not found"**

```bash
# Ensure Flutter is in PATH
flutter doctor

# If not found, manually add to PATH:
# macOS/Linux: export PATH="$PATH:/path/to/flutter/bin"
# Windows: Set-Env PATH "$env:PATH;C:\path\to\flutter\bin"
```

#### 2. **"google-services.json not found"**

```bash
# Verify file exists:
ls android/app/google-services.json

# If missing, download from Firebase Console (Section 3.1)
```

#### 3. **"Pod install failed"** (iOS)

```bash
cd ios
rm -rf Pods Podfile.lock
pod repo update
pod install
cd ..
```

#### 4. **"Keystore password incorrect"**

```bash
# Verify passwords in android/key.properties match keystore
# If unsure, you must regenerate the keystore (irreversible action)
keytool -list -v -keystore android/app/release.keystore
```

#### 5. **"Remote Config not updating"**

- Check Firebase Console → Remote Config → **Published?** (should show "Live")
- Wait 2-5 minutes for changes to propagate
- Force refresh in app: Auth → re-login or clear app data
- Check app logs: `flutter run -v`

#### 6. **"APK too large"**

```bash
# Use split-per-abi to reduce individual APK size:
flutter build apk --flavor en --release --split-per-abi

# Use App Bundle for Play Store (automatically optimizes):
flutter build appbundle --flavor en --release
```

#### 7. **"Scenarios not showing"**

**Likely causes:**
1. Remote Config `scenarios` not yet published
2. `worldviewKey` in scenario doesn't match available worldviews
3. `battleType` in scenario doesn't match selected battle type

**Debug:**
```bash
# Check Remote Config in Firebase Console
# Look for 'scenarios' parameter and verify JSON format
# Ensure worldviewKey matches worldviews[KEY].title
```

#### 8. **"Language not switching"**

Verify ARB files are synced:
- `lib/core/l10n/app_en.arb` (English)
- `lib/core/l10n/app_ja.arb` (Japanese)

Both must have all the same keys. If a key is missing from one, it won't localize properly.

#### 9. **"Build fails with 'failed to rebuild'"**

```bash
# Full clean rebuild
flutter clean
rm -rf build ios android/.gradle
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --flavor en --release
```

#### 10. **"App crashes on first launch"**

1. Check Firebase authentication is enabled (Section 3.2)
2. Verify game-config document exists in Firestore
3. Check app logs: `flutter run -v`
4. Look in Firebase Console → Crashlytics for stack trace

---

## Appendix: Useful Commands

```bash
# Check environment
flutter doctor
flutter doctor -v

# Clean & reset
flutter clean
flutter pub get

# Code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Testing
flutter test

# Analyze code for issues
flutter analyze

# Build APK
flutter build apk --flavor en --release
flutter build apk --flavor ja --release

# Build app bundle (for Play Store)
flutter build appbundle --flavor en --release

# Install on device
flutter install --flavor en

# Run with verbose logging
flutter run -v

# Format code
flutter format lib/

# List connected devices
flutter devices

# Remove app from device
adb uninstall com.example.strategy_game
```

---

## Support & Contact

**For Technical Issues:**
- Check Firebase Console logs
- Run: `flutter run -v` for detailed output
- Share crash logs from Android Studio Logcat or Xcode console

**For Configuration Questions:**
- Refer to Firebase documentation: https://firebase.flutter.dev/
- Check Flutter docs: https://flutter.dev/docs

---

**Document Version:** 1.0
**Last Updated:** April 2026
**Maintained By:** Development Team
