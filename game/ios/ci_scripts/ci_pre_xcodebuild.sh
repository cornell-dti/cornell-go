#!/bin/sh
set -e

echo "🌀 Running flutter pub get..."
cd ../../
flutter pub get

echo "🚀 Building Flutter iOS project (no codesign)..."
flutter build ios --release --no-codesign
