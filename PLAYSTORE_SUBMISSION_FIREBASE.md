# Play Store Submission Guide - LoanLedger with Firebase Authentication

Complete guide to prepare and submit the LoanLedger app to Google Play Store.

---

## Pre-Submission Checklist

### ✅ Firebase Setup
- [ ] Firebase project created at console.firebase.google.com
- [ ] Email/Password authentication enabled
- [ ] Phone number OTP authentication enabled
- [ ] `google-services.json` downloaded to `android/app/`
- [ ] SHA-1 fingerprint registered in Firebase Console

### ✅ App Configuration
- [x] App name: LoanLedger
- [x] Package name: com.santhosh.p2preminder
- [x] Minimum SDK: API 24
- [x] Target SDK: Latest
- [ ] Version code incremented
- [ ] Version name updated (e.g., 1.0.0)

### ✅ Android Build
- [ ] Release keystore created
- [ ] key.properties configured
- [ ] ProGuard enabled for release builds
- [ ] App icons provided (192x192)
- [ ] Screenshots captured (5-8 per device)
- [ ] Privacy policy prepared

---

## Step 1: Create Release Keystore

```bash
cd /Users/sundarrajan/StudioProjects/LoanLedger/android/app

keytool -genkey -v -keystore release.keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias p2p_reminder_key
```

Save the password securely!

---

## Step 2: Configure key.properties

Create `/Users/sundarrajan/StudioProjects/LoanLedger/android/key.properties`:

```properties
storeFile=app/release.keystore.jks
storePassword=YOUR_PASSWORD
keyAlias=p2p_reminder_key
keyPassword=YOUR_PASSWORD
```

**⚠️ Never commit to Git (already in .gitignore)**

---

## Step 3: Build Release App Bundle

```bash
cd /Users/sundarrajan/StudioProjects/LoanLedger

# Clean
flutter clean

# Get dependencies
flutter pub get

# Build bundle (recommended for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## Step 4: Create Google Play Console Account

1. Visit https://play.google.com/console
2. Click **Create app**
3. Fill in:
   - App name: LoanLedger
   - Category: Finance or Personalization
   - Complete content rating questionnaire

---

## Step 5: Prepare Store Listing

### Screenshots (Required)
- Phone: 9:16 aspect ratio (1080x1920)
- Minimum 2, maximum 8 per device type
- Capture: Login, Home, Add Loan, Dashboard, Settings

### App Icon
- 512x512 PNG from `assets/app_icon.png`

### Description
```
LoanLedger - Personal Loan Tracker

Track all your personal loans easily. Whether you've lent money 
to friends or borrowed from family, manage every loan with 
detailed EMI calculations and smart reminders.

FEATURES:
✅ Track lent & borrowed loans
✅ Automatic EMI calculations  
✅ Smart due date reminders
✅ WhatsApp sharing
✅ Export & import backups
✅ Multi-language support
✅ Secure local storage

Firebase Authentication:
✅ Email/Password login
✅ Phone number OTP
✅ Secure account management

PRIVACY:
Your data stays on your device. No ads, no tracking.
```

---

## Step 6: Handle Permissions

The app requests **INTERNET** permission (for Firebase auth). 

Explain in store listing: "Required for user authentication and account management."

---

## Step 7: Upload to Play Console

1. Go to **Testing** → **Internal testing**
2. Click **Create new release**
3. Upload `app-release.aab`
4. Add release notes
5. Review and save
6. Invite testers

---

## Step 8: Test Before Public Release

1. Test on multiple Android devices
2. Test login flows
3. Test phone OTP (if phone network available)
4. Verify all features work
5. Check crash reporting in Play Console

---

## Step 9: Submit to Production

1. Complete all required fields (check green checkmarks)
2. In **Production** release, upload same app bundle
3. Add meaningful release notes
4. Click **Review release**
5. Click **Start rollout to Production**

---

## After Release

### Monitor
- **Crashes**: Play Console → Vitals → Crashes
- **Ratings**: Play Console → Ratings & reviews
- **Installs**: Play Console → Statistics

### Update Strategy
- Increment `versionCode` in pubspec.yaml each release
- Major.Minor.Patch versioning (e.g., 1.0.1)
- Add clear release notes

---

## Troubleshooting

### SHA-1 Error
```bash
cd android && ./gradlew signingReport
```
Copy SHA-1 and add to Firebase Console.

### Firebase Initialization Error
Ensure `google-services.json` is in `android/app/`

### Build Errors
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

---

## Security Tips

1. **Never share** keystore password
2. **Back up** keystore file securely
3. **Protect** google-services.json (contains API keys)
4. **Use** Firebase security rules for Firestore (if used)
5. **Monitor** Firebase Console for suspicious activity

---

## Useful Links

- [Firebase Console](https://console.firebase.google.com)
- [Google Play Console](https://play.google.com/console)
- [Play Store Policies](https://play.google.com/about/developer-content-policy)
- [Flutter Release Build](https://flutter.dev/docs/deployment/android)

---

**Ready for Play Store! 🚀**

Version: 1.0.0  
Updated: October 11, 2026




