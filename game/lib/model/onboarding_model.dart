import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/user_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/challenge_model.dart';

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
  // Loading state: true until backend responds with user onboarding status
  bool _isLoadingFromBackend = true;
  bool get isLoadingFromBackend => _isLoadingFromBackend;

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

  // Backend API client for persistence
  final ApiClient _client;

  /**
   * Constructor - Initialize with API client and listen for backend updates
   */
  OnboardingModel(ApiClient client) : _client = client {
    // Listen for user data updates from backend to sync onboarding status
    client.clientApi.updateUserDataStream.listen((event) {
      // Backend responded definitively - no longer loading
      _isLoadingFromBackend = false;

      if (event.user.hasCompletedOnboarding == true) {
        // User has completed onboarding (from backend), skip all steps
        _markAllStepsComplete();
      } else {
        print('Backend says onboarding NOT complete - showing onboarding');
        // User hasn't completed onboarding, reset all flags and show it
        _resetAllSteps();
      }
    });

    // When connected, request user data to check onboarding status
    client.clientApi.connectedStream.listen((event) {
      client.serverApi?.requestUserData(RequestUserDataDto());
    });
  }

  void completeStep0() {
    step0WelcomeComplete = true;
    notifyListeners();
  }

  void completeStep1() {
    step1ChallengesComplete = true;
    notifyListeners();
  }

  void completeStep2() {
    step2JourneysComplete = true;
    notifyListeners();
  }

  void completeStep3() {
    step3JourneysExplanationComplete = true;
    notifyListeners();
  }

  void completeStep4() {
    step4FirstJourneyComplete = true;
    notifyListeners();
  }

  void completeStep5() {
    step5GameplayIntroComplete = true;
    notifyListeners();
  }

  void completeStep6() {
    step6InfoRowComplete = true;
    notifyListeners();
  }

  void completeStep7() {
    step7ImageToggleComplete = true;
    notifyListeners();
  }

  void completeStep8() {
    step8ExpandedImageComplete = true;
    notifyListeners();
  }

  void completeStep9() {
    step9RecenterButtonComplete = true;
    notifyListeners();
  }

  void completeStep10() {
    step10HintButtonComplete = true;
    notifyListeners();
  }

  void completeStep11() {
    step11ProfileTabComplete = true;
    notifyListeners();
  }

  void completeStep12() {
    step12LeaderboardTabComplete = true;
    notifyListeners();
  }

  Future<void> completeStep13() async {
    step13FinalComplete = true;
    notifyListeners();

    // Save completion to backend database permanently
    try {
      final result = await _client.serverApi?.completeOnboarding(
        CompleteOnboardingDto(),
      );
      print('✅ Backend: Onboarding completion saved to database');
    } catch (e) {
      print('Failed to save onboarding completion: $e');
    }
  }

  /**
   * Check if onboarding prerequisites are met
   * Returns true if user has at least one uncompleted challenge (any timer status)
   * AND one uncompleted timer-free journey
   */
  bool canStartOnboarding(UserModel userModel, EventModel eventModel,
      TrackerModel trackerModel, ChallengeModel challengeModel) {
    final allowedEventIds = userModel.getAvailableEventIds();

    bool hasUncompletedChallenge = false;
    bool hasTimerFreeJourney = false;

    for (final eventId in allowedEventIds) {
      final event = eventModel.getEventById(eventId);
      if (event == null) continue;

      final tracker = trackerModel.trackerByEventId(eventId);
      final numberCompleted = tracker?.prevChallenges.length ?? 0;
      final locationCount = event.challenges?.length ?? 0;
      final isComplete = (numberCompleted == locationCount);

      if (isComplete) continue;

      if (locationCount == 1) {
        // Single challenge - timer status doesn't matter
        hasUncompletedChallenge = true;
      } else if (locationCount > 1) {
        // Journey - check if any challenge has a timer
        bool journeyHasTimer = false;
        for (var challengeId in event.challenges ?? []) {
          var challenge = challengeModel.getChallengeById(challengeId);
          if (challenge?.timerLength != null && challenge!.timerLength! > 0) {
            journeyHasTimer = true;
            break;
          }
        }
        if (!journeyHasTimer) {
          hasTimerFreeJourney = true;
        }
      }

      // Early exit if both conditions met
      if (hasUncompletedChallenge && hasTimerFreeJourney) {
        return true;
      }
    }

    return hasUncompletedChallenge && hasTimerFreeJourney;
  }

  /**
   * Reset all onboarding flags
   * Also resets completion status in database
   */
  Future<void> reset() async {
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

    // Reset on backend database
    try {
      await _client.serverApi?.resetOnboarding(ResetOnboardingDto());
    } catch (e) {
      print('Failed to reset onboarding: $e');
    }
  }

  /**
   * Skip onboarding (e.g., when location unavailable)
   * Marks all steps complete locally but does NOT save to backend
   * so user will see onboarding again next session
   */
  void skipOnboarding() {
    _markAllStepsComplete();
  }

  /**
   * Internal helper: Mark all onboarding steps as complete
   * Called when backend indicates user has completed onboarding
   */
  void _markAllStepsComplete() {
    step0WelcomeComplete = true;
    step1ChallengesComplete = true;
    step2JourneysComplete = true;
    step3JourneysExplanationComplete = true;
    step4FirstJourneyComplete = true;
    step5GameplayIntroComplete = true;
    step6InfoRowComplete = true;
    step7ImageToggleComplete = true;
    step8ExpandedImageComplete = true;
    step9RecenterButtonComplete = true;
    step10HintButtonComplete = true;
    step11ProfileTabComplete = true;
    step12LeaderboardTabComplete = true;
    step13FinalComplete = true;
    notifyListeners();
  }

  /**
   * Internal helper: Reset all onboarding steps to incomplete
   * Called when backend indicates user needs to see onboarding (hasCompletedOnboarding: false)
   */
  void _resetAllSteps() {
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
  }
}
