#!/bin/bash
set -e

echo "Running all CI checks locally..."

echo "Checking Flutter format..."
cd game
dart format lib | grep '0 changed' || (echo "❌ Flutter format failed. Run 'dart format lib' to fix." && exit 1)
cd ..

echo "Checking server format..."
cd server
npm run checkformat || (echo "❌ Server format failed. Run 'npm run format' to fix." && exit 1)

echo "Checking server build..."
npm install
npx prisma generate
npm run build || (echo "❌ Server build failed." && exit 1)
cd ..

echo "Running E2E tests..."
npm run tests:e2e || (echo "❌ E2E tests failed." && exit 1)

echo "All CI checks passed! Safe to push"
