#!/bin/bash
set -e

echo "🛠 Xcode Cloud Post-Clone Script Starting..."

echo "➡️ Checking Flutter version:"
flutter --version

echo "➡️ Running flutter pub get..."
flutter pub get

echo "➡️ Building iOS (no codesign)..."
flutter build ios --no-codesign

cd ios
echo "➡️ Installing CocoaPods..."
pod install

echo "✅ Post-clone setup done!"
