# API Keys Setup Guide

---

## 1. APPLE_SHARED_SECRET (iOS)

Used to verify App Store in-app purchase receipts.

### Steps

1. Open https://appstoreconnect.apple.com and sign in.

2. Click your app from the list.

3. In the left sidebar, click "In-App Purchases".

4. Scroll down to the section called "App-Specific Shared Secret".

5. Click "Generate" if no secret exists, or "View" if one already exists.

6. Copy the 32-character string shown (example: a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4).

7. Open your terminal and run:

   firebase functions:secrets:set APPLE_SHARED_SECRET

8. Paste the 32-character string when prompted and press Enter.

9. Verify it was saved:

   firebase functions:secrets:access APPLE_SHARED_SECRET

### Notes

- If you do not have an iOS app set up yet, you can use the Master Shared Secret instead.
  Go to App Store Connect -> Users and Access -> Shared Secret -> Generate.
  This works for all your apps under the same account.
- The secret never expires unless you regenerate it.
- APPLE_SHARED_SECRET is only needed for iOS. Android-only testing does not require it.

---

## 2. GOOGLE_PLAY_SERVICE_ACCOUNT (Android)

Used to verify Google Play in-app purchase tokens via the Google Play Developer API.

### Step 1 — Link Play Console to Google Cloud

1. Open https://play.google.com/console and sign in.

2. Select your app.

3. In the left sidebar go to: Setup -> API access.

4. Click "Link to a Google Cloud project".

5. Choose your existing Firebase project (steelverdict-81c34) from the dropdown.

6. Click "Link".

### Step 2 — Create a Service Account

1. After linking, the page shows a "Service accounts" section.

2. Click "Create new service account".

3. You will be redirected to Google Cloud Console.

4. Fill in:
   - Service account name: play-billing-verifier (or any name you like)
   - Service account ID: auto-filled, leave as is
   - Description: Verifies Play Store purchases

5. Click "Create and continue".

6. For the role, click "Select a role" -> search for "Service Account User" -> select it.

7. Click "Done".

### Step 3 — Grant Permissions in Play Console

1. Go back to Play Console -> Setup -> API access.

2. Find the service account you just created in the list.

3. Click "Grant access" next to it.

4. Under "Account permissions", enable:
   - View financial data, orders, and cancellation survey responses
   - Manage orders and subscriptions

5. Click "Apply" then "Save changes".

6. Wait up to 24 hours for permissions to activate (usually takes a few minutes).

### Step 4 — Download the JSON Key File

1. Open https://console.cloud.google.com/iam-admin/serviceaccounts

2. Make sure your Firebase project (steelverdict-81c34) is selected at the top.

3. Find the service account you created (play-billing-verifier).

4. Click on it to open the details.

5. Click the "Keys" tab.

6. Click "Add Key" -> "Create new key".

7. Select "JSON" and click "Create".

8. A JSON file is downloaded to your computer automatically.
   Example filename: steelverdict-81c34-a1b2c3d4e5f6.json

### Step 5 — Set the Secret in Firebase

Option A — From file (recommended on Mac/Linux):

firebase functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT < path/to/downloaded-key.json

Option B — Paste manually (works on Windows):

1. Open the downloaded JSON file in Notepad or any text editor.

2. Select all (Ctrl+A) and copy (Ctrl+C).

3. In your terminal run:

   firebase functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT

4. Paste the entire JSON content when prompted and press Enter.

Verify it was saved:

firebase functions:secrets:access GOOGLE_PLAY_SERVICE_ACCOUNT

### Notes

- Keep the downloaded JSON file safe and do not commit it to git.
- Delete the JSON file from your computer after setting the secret.
- If the key is compromised, go to Cloud Console -> IAM -> Service Accounts
  -> Keys tab -> Delete the old key -> Create a new one -> Re-set the secret.
- The service account email looks like:
  play-billing-verifier@steelverdict-81c34.iam.gserviceaccount.com

---

## 3. After Setting Both Secrets

Deploy the functions that use these secrets:

firebase deploy --only functions:validatePurchase

Confirm the secrets are attached to the function:

firebase functions:secrets:access APPLE_SHARED_SECRET
firebase functions:secrets:access GOOGLE_PLAY_SERVICE_ACCOUNT

---

## 4. All Firebase Secrets Summary

These are all the secrets this project uses:

Secret name Used by

---

GEMINI_API_KEY submitBattle (AI calls)
CLAUDE_API_KEY submitBattle, generateWarHistory
GOOGLE_PLAY_SERVICE_ACCOUNT validatePurchase (Android)
APPLE_SHARED_SECRET validatePurchase (iOS)

Set each one with:

firebase functions:secrets:set SECRET_NAME

List all secrets currently set:

firebase functions:secrets:list
