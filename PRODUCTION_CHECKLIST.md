# EMI Reminder App - Production Release Checklist

## ✅ Code Quality
- [x] Flutter analyze passes (only info-level suggestions, no errors/warnings)
- [x] All critical features working
- [x] Backup/Restore functionality added
- [x] Proper error handling in place

## ✅ Features Verified
- [x] Add/Edit/Delete Loans
- [x] EMI due date calculation (handles month-end dates correctly)
- [x] EMI overdue detection and display
- [x] EMI Progress tracking with paid count
- [x] Mark as Paid/Unpaid functionality
- [x] Notification reminders
- [x] Calendar view
- [x] EMI Calculator
- [x] Backup to JSON file
- [x] Restore from backup file
- [x] Filter & Sort loans
- [x] Multi-currency support

## ✅ Android Configuration
- [x] AndroidManifest.xml configured with all required permissions
- [x] ProGuard rules for release build
- [x] Minification enabled for smaller APK
- [x] App icon configured
- [x] App name: "EMI Reminder"
- [x] Package ID: com.santhosh.emi.emi_reminder

## ⚠️ Before Play Store Release

### 1. Update Keystore (IMPORTANT!)
Edit `android/key.properties` with your actual keystore:
```properties
storePassword=YOUR_ACTUAL_PASSWORD
keyPassword=YOUR_ACTUAL_PASSWORD
keyAlias=upload
storeFile=keystore/upload-keystore.jks
```

### 2. Update build.gradle.kts for Release Signing
In `android/app/build.gradle.kts`, change:
```kotlin
release {
    signingConfig = signingConfigs.getByName("release")  // Change from "debug"
}
```

### 3. Update Version Number
In `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Update for each release
```

### 4. Build Commands
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### 5. Test Release Build
- Install release APK on a real device
- Test all features without debugger
- Verify notifications work
- Test backup/restore

## 📱 Permissions Required
| Permission | Purpose |
|------------|---------|
| POST_NOTIFICATIONS | Show EMI reminders |
| SCHEDULE_EXACT_ALARM | Schedule precise reminders |
| RECEIVE_BOOT_COMPLETED | Reschedule after restart |
| VIBRATE | Notification vibration |
| WAKE_LOCK | Wake device for notification |

## 📦 APK Location
After build, APK is at:
`build/app/outputs/flutter-apk/app-release.apk`

## 🎯 Play Store Requirements
- [x] Privacy Policy (privacy_policy.html)
- [ ] Store listing screenshots
- [ ] Feature graphic (1024x500)
- [ ] App description
- [ ] Content rating questionnaire

## 🔧 Debug Info to Remove
The app currently has some debug prints. For production, you may want to:
1. Remove `debugPrint` statements or wrap them in `kDebugMode` checks
2. Remove the debug banner (already done via `debugShowCheckedModeBanner: false`)

---
Last Updated: January 29, 2026
