# Steel Verdict - Complete Setup and Build Guide

## Overview
Steel Verdict is a Flutter-based strategy game app that supports both English and Japanese languages. This guide provides a comprehensive setup for developers and clients to configure, build, and deploy the app on Android devices.

## Prerequisites

### System Requirements
- **Operating System**: Windows 10/11, macOS 10.15+, or Linux (Ubuntu 18.04+)
- **Flutter SDK**: Version 3.19.0 or later
- **Dart SDK**: Included with Flutter (version 3.3.0+)
- **Android Studio**: Version 2022.3.1 or later (for Android development)
- **Java Development Kit (JDK)**: Version 11 or 17 (OpenJDK recommended)
- **Git**: Version 2.25+ for version control

### Hardware Requirements
- **RAM**: Minimum 8GB, recommended 16GB+
- **Storage**: At least 10GB free space
- **Processor**: Intel i5/AMD Ryzen 5 or better

### Required Accounts
- **Google Account**: For Firebase, Google Play Console, and AdMob
- **Apple Developer Account**: For iOS builds (if deploying to iOS)
- **GitHub Account**: For accessing the repository

## Project Setup

### 1. Install Flutter SDK
1. Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Extract to a directory (e.g., `C:\flutter` on Windows)
3. Add Flutter to your PATH:
   - Windows: Add `C:\flutter\bin` to environment variables
   - macOS/Linux: Add to `.bashrc` or `.zshrc`: `export PATH="$PATH:/path/to/flutter/bin"`
4. Verify installation:
   ```bash
   flutter doctor
   ```
   Fix any issues shown (Android SDK, Xcode for iOS, etc.)

### 2. Clone the Repository
```bash
git clone https://github.com/your-organization/steel-verdict.git
cd steel-verdict
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Android Setup
1. **Install Android Studio**:
   - Download from [developer.android.com/studio](https://developer.android.com/studio)
   - Install Android SDK, Android SDK Platform, Android Virtual Device

2. **Configure Android SDK**:
   - Open Android Studio > SDK Manager
   - Install SDK Platforms: API 33 (Android 13), API 34 (Android 14)
   - Install SDK Tools: Android SDK Build-Tools 34.0.0, Android Emulator

3. **Set Android SDK Path**:
   - In Android Studio: File > Settings > Appearance & Behavior > System Settings > Android SDK
   - Or set environment variable: `ANDROID_HOME=C:\Users\YourUser\AppData\Local\Android\Sdk`

4. **Accept Android SDK Licenses**:
   ```bash
   flutter doctor --android-licenses
   ```

### 5. Firebase Setup

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project: "Steel Verdict"
3. Enable Authentication, Firestore, Remote Config, Analytics, and Crashlytics

#### Android Configuration
1. In Firebase Console: Project Settings > General > Your apps > Add app
2. Choose Android, package name: `com.example.strategy_game` (check `android/app/build.gradle` for exact name)
3. Download `google-services.json` and place it in `android/app/`

#### iOS Configuration (if needed)
1. Add iOS app in Firebase Console
2. Download `GoogleService-Info.plist` and place in `ios/Runner/`

#### Firestore Setup
1. In Firebase Console: Firestore Database > Create database
2. Choose "Start in test mode" for development
3. Import initial data from `docs/firestore_game_config_seed.json`

#### Remote Config Setup
1. In Firebase Console: Remote Config
2. Add parameters from `docs/remote_config_guide.md`
3. Publish the configuration

### 6. API Keys and Secrets Setup

#### Firebase Configuration
- Ensure `firebase_options.dart` is properly configured
- Update `lib/firebase_options.dart` with your Firebase project details

#### AdMob Setup
1. Go to [AdMob Console](https://admob.google.com/)
2. Create an AdMob account and app
3. Get Ad Unit IDs for rewarded and interstitial ads
4. Update `lib/services/ads/admob_ad_service.dart` with your Ad Unit IDs

#### In-App Purchase Setup
1. For Android: Google Play Console > Monetization > Products
2. Create subscriptions and in-app products
3. Update product IDs in `lib/services/purchase/iap_purchase_service.dart`

#### AI API Keys
1. **Google Gemini**: Get API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. **Anthropic Claude**: Get API key from [Anthropic Console](https://console.anthropic.com/)
3. Update `docs/api_keys_setup.md` with your keys
4. Ensure keys are securely stored (use environment variables or secure storage)

### 7. Localization Setup

#### English and Japanese Support
The app uses Flutter's internationalization (i18n) with ARB files.

1. **Generate Localization Files**:
   ```bash
   flutter gen-l10n
   ```

2. **Update ARB Files**:
   - English: `lib/core/l10n/app_en.arb`
   - Japanese: `lib/core/l10n/app_ja.arb`

3. **Test Localization**:
   - Change device language in Android/iOS settings
   - Or use Flutter's locale override in code

4. **Add New Strings**:
   - Add entries to both ARB files
   - Run `flutter gen-l10n` to regenerate

## Building the APK

### 1. Prepare for Build
1. **Update Build Configuration**:
   - Check `android/app/build.gradle` for version codes and names
   - Update `pubspec.yaml` version if needed

2. **Clean and Get Dependencies**:
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Generate Assets**:
   ```bash
   flutter gen-l10n
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

### 2. Build APK for Release
```bash
flutter build apk --release
```

This creates `build/app/outputs/flutter-apk/app-release.apk`

### 3. Build APK with Split APKs (for different architectures)
```bash
flutter build apk --release --split-per-abi
```

This creates separate APKs for:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (Intel x64)

### 4. Build App Bundle (AAB) for Google Play
```bash
flutter build appbundle --release
```

This creates `build/app/outputs/bundle/release/app-release.aab`

### 5. Sign the APK (for distribution)
1. **Create Keystore** (if not exists):
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Configure Signing**:
   - Create `android/key.properties`:
     ```
     storePassword=your_store_password
     keyPassword=your_key_password
     keyAlias=upload
     storeFile=../upload-keystore.jks
     ```

3. **Update `android/app/build.gradle`**:
   ```gradle
   android {
       ...
       signingConfigs {
           release {
               keyAlias keystoreProperties['keyAlias']
               keyPassword keystoreProperties['keyPassword']
               storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
               storePassword keystoreProperties['keyPassword']
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
           }
       }
   }
   ```

4. **Build Signed APK**:
   ```bash
   flutter build apk --release
   ```

## Testing

### 1. Run on Emulator/Device
```bash
flutter run
```

### 2. Run Tests
```bash
flutter test
```

### 3. Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

### 4. Localization Testing
- Test both English and Japanese interfaces
- Verify all strings are properly localized

## Deployment

### Google Play Store
1. **Create Google Play Developer Account**
2. **Upload AAB**:
   - Go to Google Play Console > Release > Production
   - Upload `app-release.aab`
3. **Configure Store Listing**:
   - Add app description, screenshots, icons
   - Set pricing and distribution
4. **Publish**:
   - Submit for review

### App Store (iOS)
1. **Create Apple Developer Account**
2. **Build IPA**:
   ```bash
   flutter build ios --release
   ```
3. **Upload to App Store Connect**:
   - Use Xcode or Transporter app
4. **Configure App Store Listing**
5. **Submit for Review**

## Troubleshooting

### Common Issues

1. **Flutter Doctor Errors**:
   - Ensure all prerequisites are installed
   - Update Flutter: `flutter upgrade`

2. **Build Failures**:
   - Clean project: `flutter clean && flutter pub get`
   - Check for deprecated APIs in code

3. **Firebase Issues**:
   - Verify `google-services.json` is in correct location
   - Check Firebase project configuration

4. **Localization Not Working**:
   - Run `flutter gen-l10n`
   - Restart app after language change

5. **APK Installation Issues**:
   - Enable "Unknown Sources" on Android device
   - Check device architecture compatibility

### Performance Optimization
- Use `flutter build apk --release --obfuscate --split-debug-info=build/debug-info`
- Analyze bundle size: `flutter analyze --preamble`
- Profile app: `flutter run --profile`

## Maintenance

### Updating Dependencies
```bash
flutter pub outdated
flutter pub upgrade
```

### Code Generation
```bash
flutter pub run build_runner build
flutter gen-l10n
```

### Version Management
- Update version in `pubspec.yaml`
- Update version code in `android/app/build.gradle`
- Tag releases in Git

## Support

For additional help:
- Check project documentation in `docs/`
- Review Firebase and Flutter documentation
- Contact development team at your@example.com

---

**Last Updated**: April 6, 2026
**Version**: 1.0.0</content>
<parameter name="filePath">c:\Users\baby0\Music\flutter\strategy_game\docs\setup_and_build_guide.md