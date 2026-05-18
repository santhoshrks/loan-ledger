#!/bin/bash
# Script to update app icon

echo "📱 EMI Reminder App - Icon Update Script"
echo "========================================="
echo ""
echo "Please follow these steps to update your app icon:"
echo ""
echo "1. Save the new calendar icon image as:"
echo "   /Users/sundarrajan/StudioProjects/emi_reminder/assets/app_icon.png"
echo ""
echo "   Requirements:"
echo "   - Format: PNG"
echo "   - Minimum size: 1024x1024 px (recommended)"
echo "   - Transparent background optional (will use white background for adaptive icon)"
echo ""
echo "2. After saving the image, run this command:"
echo "   cd /Users/sundarrajan/StudioProjects/emi_reminder"
echo "   flutter pub run flutter_launcher_icons"
echo ""
echo "3. Then rebuild your app:"
echo "   flutter clean"
echo "   flutter build appbundle --release"
echo ""
echo "========================================="
echo ""
echo "Current icon backup saved as: assets/app_icon_old_backup.png"
echo ""

# Check if new icon file exists
if [ -f "/Users/sundarrajan/StudioProjects/emi_reminder/assets/app_icon.png" ]; then
    echo "✅ Icon file found!"

    # Get file size
    SIZE=$(stat -f%z "/Users/sundarrajan/StudioProjects/emi_reminder/assets/app_icon.png")
    echo "   File size: $SIZE bytes"

    # Check if it's a PNG
    FILE_TYPE=$(file "/Users/sundarrajan/StudioProjects/emi_reminder/assets/app_icon.png")
    echo "   File type: $FILE_TYPE"

    echo ""
    read -p "Do you want to generate app icons now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd /Users/sundarrajan/StudioProjects/emi_reminder
        echo "🔄 Generating app icons..."
        flutter pub run flutter_launcher_icons
        echo ""
        echo "✅ Done! App icons generated."
        echo ""
        echo "Next steps:"
        echo "1. Test the app with: flutter run"
        echo "2. Build release: flutter build appbundle --release"
    fi
else
    echo "⚠️  Icon file not found yet."
    echo "   Please save your image to: assets/app_icon.png"
fi

