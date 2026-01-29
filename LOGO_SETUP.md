# Logo Setup Guide

## App Name
**Smart EMI: Loan Reminder App**

## Quick Setup (3 Steps)

### Step 1: Save Your Logo Image
Save the logo image as `app_icon.png` in the `assets/` folder:
```
assets/app_icon.png   (512x512 px recommended)
```

### Step 2: Generate Icons
Run this command in the terminal:
```bash
cd /Users/sundarrajan/StudioProjects/emi_reminder
dart run flutter_launcher_icons
```

### Step 3: Build App
```bash
flutter build apk --release
```

---

## Logo Files That Will Be Generated

### Android App Icons (Auto-generated)

| Folder | Size |
|--------|------|
| `mipmap-mdpi/` | 48x48 px |
| `mipmap-hdpi/` | 72x72 px |
| `mipmap-xhdpi/` | 96x96 px |
| `mipmap-xxhdpi/` | 144x144 px |
| `mipmap-xxxhdpi/` | 192x192 px |

### Configuration in pubspec.yaml
```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/app_icon.png"
```

## Logo Design Colors
- **Primary Blue:** #1A3A5C (Triangle)
- **Accent Green:** #4CAF50 (Arrow)
- **Gold:** #D4A017 (Rupee symbol)
- **Background:** #FFFFFF (White)

## Current App Branding

| Element | Value |
|---------|-------|
| App Name (Short) | EMI Reminder |
| App Name (Full) | EMI Reminder & Loan Tracker |
| Tagline | Loan Tracker |
| Package Name | com.santhosh.emi.emi_reminder |
