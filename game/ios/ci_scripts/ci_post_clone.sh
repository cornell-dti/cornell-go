#!/bin/sh
set -e

echo "🛠 Installing CocoaPods via Homebrew..."
brew install cocoapods

echo "📦 Running pod install..."
pod install

echo "✅ Done!"
