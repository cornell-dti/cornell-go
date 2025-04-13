#!/bin/bash
set -e

echo "🔧 Running Flutter pre-build setup for iOS..."

flutter --version
flutter pub get

flutter build ios --no-codesign

cd ios
pod install

echo "✅ Done setting up for Xcode Cloud!"
