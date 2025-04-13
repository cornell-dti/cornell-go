#!/bin/bash
set -e

echo "🛠 Xcode Cloud Pre-Build Script Starting..."

echo "➡️ Checking Flutter version:"
which flutter || echo "❌ Flutter not found"
flutter --version || echo "❌ Failed to get Flutter version"

echo "➡️ Running flutter pub get..."
flutter pub get

echo "➡️ Building iOS without codesign..."
flutter build ios --no-codesign

echo "➡️ Installing CocoaPods..."
cd ios
pod install

echo "✅ Xcode Cloud Pre-Build Script Completed!"
