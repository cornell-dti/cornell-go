#!/bin/bash
set -e

echo "🛠 Xcode Cloud Pre-Build Script Starting..."

echo "🧭 PATH = $PATH"
echo "➡️ Checking if Flutter is available..."

# Try resolving flutter via login shell
if ! command -v flutter &> /dev/null; then
    echo "🔄 Trying login shell path resolution..."
    export PATH="$PATH:$HOME/flutter/bin:$HOME/.pub-cache/bin"
fi

# Confirm it's now available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is still not available in PATH"
    exit 1
fi

echo "✅ Flutter found at: $(which flutter)"
flutter --version

echo "➡️ Running flutter pub get..."
flutter pub get

echo "➡️ Building iOS (no codesign)..."
flutter build ios --no-codesign

cd ios
echo "➡️ Installing CocoaPods..."
pod install

echo "✅ Pre-build setup done!"
