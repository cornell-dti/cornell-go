#!/bin/sh
set -e

echo "📦 Installing CocoaPods..."
brew install cocoapods

echo "⬇️ Downloading Flutter SDK..."
curl -sLO "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.29.0-stable.zip"
unzip -qq flutter_macos_3.29.0-stable.zip -d $HOME
export PATH="$PATH:$HOME/flutter/bin"

echo "🌀 Running flutter pub get..."
cd ../../  # From ios/ci_scripts to game/
flutter pub get

echo "🚀 Building Flutter iOS release build..."
flutter build ios --release

echo "📦 Running pod install..."
cd ios
pod install

echo "✅ Flutter iOS build and setup complete!"
