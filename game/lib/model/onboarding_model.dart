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
  bool step5GameplayIntroComplete = false; // Gameplay map intro (gameplay_page)
  bool step6InfoRowComplete = false; // Info row (gameplay_page)
  bool step7ImageToggleComplete = false; // Image toggle button (gameplay_map)
  bool step8ExpandedImageComplete = false; // Expanded image view (gameplay_map)
  bool step9RecenterButtonComplete = false; // Recenter button (gameplay_map)
  bool step10HintButtonComplete = false; // Hint button (gameplay_map)
  bool step11ProfileTabComplete = false; // Profile tab (bottom_navbar)
  bool step12LeaderboardTabComplete = false; // Leaderboard tab (bottom_navbar)
  bool step13FinalComplete = false; // Final goodbye overlay (bottom_navbar)

  // GlobalKeys for triggering showcases across pages
  final GlobalKey step1ChallengeCardKey = GlobalKey();
  final GlobalKey step2JourneysTabKey = GlobalKey();
  final GlobalKey step4FirstJourneyCardKey = GlobalKey();
  final GlobalKey step6InfoRowKey = GlobalKey();
  final GlobalKey step7ImageToggleKey = GlobalKey();
  final GlobalKey step8ExpandedImageKey = GlobalKey();
  final GlobalKey step9RecenterButtonKey = GlobalKey();
  final GlobalKey step10HintButtonKey = GlobalKey();
  final GlobalKey step11ProfileTabKey = GlobalKey();
  final GlobalKey step12LeaderboardTabKey = GlobalKey();

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
   * Mark step 5 (gameplay map intro) complete
   */
  void completeStep5() {
    step5GameplayIntroComplete = true;
    notifyListeners();
    print('✅ Step 5: Gameplay map intro complete');
  }

  /**
   * Mark step 6 (info row) complete
   */
  void completeStep6() {
    step6InfoRowComplete = true;
    notifyListeners();
    print('✅ Step 6: Info row complete');
  }

  /**
   * Mark step 7 (image toggle button) complete
   */
  void completeStep7() {
    step7ImageToggleComplete = true;
    notifyListeners();
    print('✅ Step 7: Image toggle button complete');
  }

  /**
   * Mark step 8 (expanded image view) complete
   */
  void completeStep8() {
    step8ExpandedImageComplete = true;
    notifyListeners();
    print('✅ Step 8: Expanded image view complete');
  }

  /**
   * Mark step 9 (recenter button) complete
   */
  void completeStep9() {
    step9RecenterButtonComplete = true;
    notifyListeners();
    print('✅ Step 9: Recenter button complete');
  }

  /**
   * Mark step 10 (hint button) complete
   */
  void completeStep10() {
    step10HintButtonComplete = true;
    notifyListeners();
    print('✅ Step 10: Hint button complete');
  }

  /**
   * Mark step 11 (profile tab) complete
   */
  void completeStep11() {
    step11ProfileTabComplete = true;
    notifyListeners();
    print('✅ Step 11: Profile tab complete');
  }

  /**
   * Mark step 12 (leaderboard tab) complete
   */
  void completeStep12() {
    step12LeaderboardTabComplete = true;
    notifyListeners();
    print('✅ Step 12: Leaderboard tab complete');
  }

  /**
   * Mark step 13 (final goodbye overlay) complete
   */
  void completeStep13() {
    step13FinalComplete = true;
    notifyListeners();
    print('✅ Step 13: Final onboarding complete! 🎉');
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
    step5GameplayIntroComplete = false;
    step6InfoRowComplete = false;
    step7ImageToggleComplete = false;
    step8ExpandedImageComplete = false;
    step9RecenterButtonComplete = false;
    step10HintButtonComplete = false;
    step11ProfileTabComplete = false;
    step12LeaderboardTabComplete = false;
    step13FinalComplete = false;
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
