import 'package:flutter/material.dart';
import 'package:game/test_onboarding.dart';

/**
 * TEST RUNNER for onboarding proof-of-concept
 * 
 * To run this test:
 * flutter run -t lib/test_onboarding_main.dart
 * 
 * This bypasses the entire app and just tests if:
 * - bottom_navbar can start showcases
 * - showcases appear on child pages
 * - navigation between pages works
 */

void main() {
  runApp(const TestOnboardingApp());
}
