# Firebase Setup Guide for P2P Reminder App

This guide will help you set up Firebase Authentication for the P2P Reminder app.

## Prerequisites

- Firebase account (free at https://firebase.google.com)
- Google Cloud Project
- Android app registered in Firebase Console

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Create a project**
3. Enter project name: `P2PReminderApp` (or any name)
4. Click **Continue**
5. Enable/Disable Google Analytics (optional)
6. Click **Create project**
7. Wait for project creation to complete

---

## Step 2: Register Android App

1. In Firebase Console, click the **Android** icon to add Android app
2. Fill in the details:
   - **Package name**: `com.santhosh.p2preminder` (from your project)
   - **App nickname**: `P2P Reminder` (optional)
   - **SHA-1 certificate fingerprint** (see below)
3. Click **Register app**

### Getting SHA-1 Certificate Fingerprint

Run this command in your terminal:

```bash
cd /Users/sundarrajan/StudioProjects/LoanLedger/android
./gradlew signingReport
```

Look for debug variant SHA1 certificate. Copy the entire SHA-1 value.

---

## Step 3: Download google-services.json

1. After registering the app, click **Download google-services.json**
2. Save file to: `/Users/sundarrajan/StudioProjects/LoanLedger/android/app/`
3. This file contains your Firebase project credentials

---

## Step 4: Enable Authentication Methods

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable these providers:
   - **Email/Password**
   - **Phone Number**

---

## Step 5: Build and Test

```bash
cd /Users/sundarrajan/StudioProjects/LoanLedger
flutter pub get
flutter run
```

---

**Last Updated**: October 11, 2026

