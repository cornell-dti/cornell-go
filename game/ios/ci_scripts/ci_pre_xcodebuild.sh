#!/bin/sh
set -e

export PATH="$PATH:$HOME/flutter/bin"

echo "🌀 Running flutter pub get..."
cd ../../
flutter pub get

echo "🚀 Building Flutter iOS (no codesign)..."
flutter build ios --release --no-codesign
