#!/bin/sh
set -e

echo "📦 Installing CocoaPods..."
brew install cocoapods

echo "⬇️ Downloading Flutter SDK..."
curl -sLO "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.29.0-stable.zip"
unzip -qq flutter_macos_3.29.0-stable.zip -d $HOME
export PATH="$PATH:$HOME/flutter/bin"

echo "🌀 Running flutter pub get..."
cd ../../  # This brings you from ios/ci_scripts/ to game/
flutter pub get

echo "📄 Creating .env file for flutter_config_plus"
echo "IOS_MAP_API_KEY=$IOS_MAP_API_KEY" >> .env

echo "📦 Running pod install..."
cd ios
pod install

echo "✅ Flutter and CocoaPods setup complete!"
