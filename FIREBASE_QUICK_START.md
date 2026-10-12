# Firebase Setup - Quick Start Guide

## Step 1: Create Firebase Project

1. Go to https://console.firebase.google.com/
2. Click **Create a project**
3. Enter name: `LoanLedger` or similar
4. Click **Continue**
5. Enable/Disable Analytics (optional)
6. Click **Create project**
7. Wait for completion

---

## Step 2: Register Your Android App

1. In Firebase Console home, click **Android icon** to add Android app
2. Fill in:
   - **Package name**: `com.santhosh.loanledger`
   - **App nickname**: `LoanLedger`
   - **SHA-1 certificate**: (See below)

### Get SHA-1 Fingerprint

Run this in your terminal:

```bash
cd /Users/sundarrajan/StudioProjects/LoanLedger/android
./gradlew signingReport
```

Look for the output like:
```
Debug Variant
SHA1: AA:BB:CC:DD:...
```

Copy the entire SHA-1 string (without spaces, or with colons - Firebase will accept both formats).

3. Paste SHA-1 into Firebase Console
4. Click **Register app**

---

## Step 3: Download google-services.json

1. Firebase Console will show a **"Download google-services.json"** button
2. Click it to download
3. Save it to: `/Users/sundarrajan/StudioProjects/LoanLedger/android/app/google-services.json`

---

## Step 4: Enable Authentication Methods

1. In Firebase Console left sidebar: **Authentication** → **Sign-in method**
2. Click **Email/Password**
   - Enable toggle
   - Click **Save**
3. Click **Phone**
   - Enable toggle
   - (Optional) Add test phone numbers for testing
   - Click **Save**

---

## Step 5: Build Again

Once you've placed the real `google-services.json`:

```bash
cd /Users/sundarrajan/StudioProjects/LoanLedger
flutter clean
flutter pub get
flutter run
```

---

## Having Trouble Finding SHA-1?

If `./gradlew signingReport` doesn't work:

```bash
cd /Users/sundarrajan/StudioProjects/LoanLedger
flutter run
```

This will also generate debug keys and show the SHA-1 in the error message.

---

**⏱️ This usually takes 5-10 minutes. Once you download google-services.json, the app will build successfully!**




