import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/**
 * `OnboardingModel` - Manages onboarding state across the app using ChangeNotifier pattern.
 *
 * @remarks
 * Each page listens via Selector and reacts to specific state changes automatically.
 * 
 * Architecture:
 * - Each page registers with its own showcase scope
 * - Pages use Selector<OnboardingModel> to listen to specific properties without rebuilding entire widget tree
 * - Flags reset when app closes (user sees onboarding again next launch)
 * - Keys stored here with lazy initialization to prevent hot restart duplicate key errors
 * - TODO: Later integrate with backend database to check user.hasCompletedOnboarding
 */
class OnboardingModel extends ChangeNotifier {
  // Completion flags for each onboarding step/page (session only)
  bool step0WelcomeComplete = false; // Welcome overlay (bottom_navbar)
  bool step1ChallengesComplete =
      false; // First challenge card (challenges_page)
  bool step2JourneysComplete = false; // Journeys tab (home_navbar)
  bool step3JourneysExplanationComplete =
      false; // Journeys page explanation (journeys_page)
  bool step4FirstJourneyComplete = false; // First journey card (journeys_page)

  // GlobalKeys for triggering showcases across pages
  final GlobalKey step1ChallengeCardKey = GlobalKey();
  final GlobalKey step2JourneysTabKey = GlobalKey();
  final GlobalKey step4FirstJourneyCardKey = GlobalKey();

  // TODO: Add more flags and keys for each Figma screen (up to 12 total)

  /**
   * Mark step 0 (welcome overlay) complete
   */
  void completeStep0() {
    step0WelcomeComplete = true;
    notifyListeners(); // Triggers ChallengesPage Consumer to rebuild
    print('✅ Step 0: Welcome complete');
  }

  /**
   * Mark step 1 (challenge card) complete
   */
  void completeStep1() {
    step1ChallengesComplete = true;
    notifyListeners();
    print('✅ Step 1: Challenges page complete');
  }

  /**
   * Mark step 2 (journeys tab) complete
   */
  void completeStep2() {
    step2JourneysComplete = true;
    notifyListeners();
    print('✅ Step 2: Journeys tab complete');
  }

  /**
   * Mark step 3 (journeys page explanation) complete
   */
  void completeStep3() {
    step3JourneysExplanationComplete = true;
    notifyListeners();
    print('✅ Step 3: Journeys page explanation complete');
  }

  /**
   * Mark step 4 (first journey card) complete
   */
  void completeStep4() {
    step4FirstJourneyComplete = true;
    notifyListeners();
    print('✅ Step 4: First journey card complete');
  }

  /**
   * Reset all onboarding flags (for testing)
   */
  void reset() {
    step0WelcomeComplete = false;
    step1ChallengesComplete = false;
    step2JourneysComplete = false;
    step3JourneysExplanationComplete = false;
    step4FirstJourneyComplete = false;

    notifyListeners();
    print('🔄 Onboarding reset');
  }

  /**
   * TODO: Check backend database for permanent completion status
   * This should be called once at app startup to load user's onboarding status
   * from the backend. For now, we show onboarding every app session.
   * 
   * Example:
   * Future<void> loadFromDatabase(ApiClient client) async {
   *   final user = await client.getCurrentUser();
   *   if (user.hasCompletedOnboarding) {
   *     step0WelcomeComplete = true;
   *     step1ChallengesComplete = true;
   *     // ... mark all as complete
   *     notifyListeners();
   *   }
   * }
   */
}
