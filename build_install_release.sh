#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

if [ ! -f "android/key.properties" ]; then
    echo "⚠️  No android/key.properties found. The app will be built using debug signatures."
    echo "   To sign with a release key, create a key.properties file with your keystore path and passwords."
fi

# Extract version from pubspec.yaml
VERSION=$(grep '^version: ' pubspec.yaml | head -1 | awk '{print $2}' | cut -d '+' -f 1)
BUILD_NUMBER=$(grep '^version: ' pubspec.yaml | head -1 | awk '{print $2}' | cut -d '+' -f 2)

if [ -z "$BUILD_NUMBER" ] || [ "$BUILD_NUMBER" == "$VERSION" ]; then
    BUILD_NUMBER=1
fi

echo "📦 Extracted version: $VERSION+$BUILD_NUMBER"

echo "🛠️  Building the production APK..."
flutter build apk --release --build-name="$VERSION" --build-number="$BUILD_NUMBER"

OUTPUT_APK="build/app/outputs/flutter-apk/food_locker-${VERSION}-${BUILD_NUMBER}.apk"
mv build/app/outputs/flutter-apk/app-release.apk "$OUTPUT_APK"

echo "✅  Build successful! The APK is located at: $OUTPUT_APK"

# Check if a device is connected and ask to install
echo "📱 Attempting to install the app on a connected device..."
if flutter devices | grep -q "android"; then
    flutter install --release --build-name="$VERSION" --build-number="$BUILD_NUMBER"
    echo "🎉  App installed successfully. You can now launch it on your phone!"
else
    echo "⚠️  No compatible device found. Connect an Android device with USB debugging enabled, and run 'flutter install --release' manually."
fi

# Alternative note for running direct
echo "💡 Tip: If you want to build and run the release version directly in one command, you can use: 'flutter run --release'"
