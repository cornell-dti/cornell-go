import 'package:game/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:game/gameplay/gameplay_page.dart';
import 'package:game/navigation_page/bottom_navbar.dart';
import 'package:game/progress_indicators/circular_progress_indicator.dart';

// for backend connection
import 'package:provider/provider.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/api/game_api.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/tracker_model.dart';
// TIMER: TimerModel import
import 'package:game/model/timer_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/challenge_model.dart';
// QUIZ: QuizModel import
import 'package:game/model/quiz_model.dart';
import 'package:game/utils/utility_functions.dart';
import 'dart:math';
// QUIZ: dart:async import for Completer
import 'dart:async';

import 'package:flutter_svg/flutter_svg.dart';

// TIMER: LoadingBar widget (unchanged from Timer version)
class LoadingBar extends StatelessWidget {
  final int totalTasks;
  final int tasksFinished;

  const LoadingBar(this.tasksFinished, this.totalTasks);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: MediaQuery.sizeOf(context).width * 0.66,
          height: 20,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: new BoxDecoration(
                        color: AppColors.lightGray,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                      ),
                    ),
                  ),
                  Container(
                    width: (totalTasks > 0 ? tasksFinished / totalTasks : 0) *
                        constraints.maxWidth,
                    height: constraints.maxHeight,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: new BoxDecoration(
                        color: AppColors.primaryRed.withAlpha(197),
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                      ),
                    ),
                  ),
                  Container(
                    height: 5,
                    width: max(
                      (totalTasks > 0 ? tasksFinished / totalTasks : 0) *
                              constraints.maxWidth -
                          16,
                      0,
                    ),
                    margin: EdgeInsets.only(left: 8, top: 3),
                    alignment: Alignment.centerLeft,
                    decoration: new BoxDecoration(
                      color: AppColors.lightRedBackground.withAlpha(153),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Text(" "),
              SvgPicture.asset("assets/icons/pin.svg"),
              Text(
                " " + tasksFinished.toString() + "/" + totalTasks.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChallengeCompletedPage extends StatefulWidget {
  final String challengeId;
  const ChallengeCompletedPage({Key? key, required this.challengeId})
      : super(key: key);

  @override
  State<ChallengeCompletedPage> createState() => _ChallengeCompletedState();
}

class _ChallengeCompletedState extends State<ChallengeCompletedPage> {
  // TIMER: journeyPage state for toggle between challenge view and journey view
  bool journeyPage = false;
  // BOTH: journeyCompleted state
  bool journeyCompleted = false;

  // QUIZ: Quiz-related state variables
  int totalQuizPoints = 0;
  bool isLoadingQuizPoints = false;
  Map<String, int> quizPointsByChallenge = {};

  @override
  void initState() {
    super.initState();
  }

  // QUIZ: Method to fetch quiz points for all challenges in a journey
  Future<void> _fetchQuizPointsForJourney(
    ApiClient apiClient,
    List<PrevChallengeDto> prevChallenges,
    EventModel eventModel,
  ) async {
    if (isLoadingQuizPoints) return;

    setState(() {
      isLoadingQuizPoints = true;
      totalQuizPoints = 0;
      quizPointsByChallenge.clear();
    });

    final completer = Completer<void>();
    final expectedChallenges = prevChallenges.length;
    int receivedCount = 0;

    // Listen for quiz progress responses
    final subscription = apiClient.clientApi.quizProgressStream.listen((
      progress,
    ) {
      if (mounted) {
        setState(() {
          if (!quizPointsByChallenge.containsKey(progress.challengeId)) {
            quizPointsByChallenge[progress.challengeId] =
                progress.totalPointsEarned;
            totalQuizPoints = quizPointsByChallenge.values.fold(
              0,
              (sum, points) => sum + points,
            );
            receivedCount++;

            if (receivedCount >= expectedChallenges && !completer.isCompleted) {
              completer.complete();
            }
          }
        });
      }
    });

    // Request quiz progress for each challenge
    for (var prevChallenge in prevChallenges) {
      apiClient.serverApi?.getQuizProgress(
        RequestQuizQuestionDto(challengeId: prevChallenge.challengeId),
      );
    }

    // Wait for all responses with timeout (1s per challenge)
    try {
      await completer.future.timeout(
        Duration(seconds: 1 * expectedChallenges),
        onTimeout: () {},
      );
    } catch (e) {}

    await subscription.cancel();

    if (mounted) {
      setState(() {
        isLoadingQuizPoints = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // MERGED: Consumer6 + context.watch for QuizModel (Consumer7 doesn't exist)
    // Timer had: ChallengeModel, EventModel, TrackerModel, TimerModel, ApiClient, GroupModel
    // Quiz had:  ChallengeModel, EventModel, TrackerModel, ApiClient, GroupModel, QuizModel
    // Merged:    Consumer6 with TimerModel, QuizModel accessed via context.watch
    return Consumer6<ChallengeModel, EventModel, TrackerModel, TimerModel,
        ApiClient, GroupModel>(
      builder: (
        context,
        challengeModel,
        eventModel,
        trackerModel,
        timerModel,
        apiClient,
        groupModel,
        _,
      ) {
        final quizModel = context.watch<QuizModel>();
        var eventId = groupModel.curEventId;
        var event = eventModel.getEventById(eventId ?? "");
        var tracker = trackerModel.trackerByEventId(eventId ?? "");

        if (tracker == null || tracker.prevChallenges.length == 0) {
          return CircularIndicator();
        }

        // BOTH: Check if this event is a journey (multiple challenges)
        // Timer used: (event?.challenges?.length ?? 0) > 1 inline
        // Quiz used: final isJourney = ...
        final isJourney = (event?.challenges?.length ?? 0) > 1;

        // BOTH: Determine whether the journey is done
        if (isJourney) {
          journeyCompleted =
              tracker.prevChallenges.length == (event?.challenges?.length ?? 0);
        }

        var challenge = challengeModel.getChallengeById(
          tracker.prevChallenges.last.challengeId,
        );

        if (challenge == null) {
          return Scaffold(body: Text("No challenge data"));
        }

        // TIMER: Get extensions used from TimerModel (check if timer was for this challenge)
        // Also fallback to prevChallenges.last.extensionsUsed for when navigating back
        int extensionsUsed = (timerModel.currentChallengeId == challenge.id)
            ? timerModel.extensionsUsed
            : (tracker.prevChallenges.last.extensionsUsed ?? 0);

        // BOTH: Build list of completed challenge text fields to display later
        var total_pts = 0;
        List<Widget> completedChallenges = [];
        for (PrevChallengeDto prevChal in tracker.prevChallenges) {
          var completedChal = challengeModel.getChallengeById(
            prevChal.challengeId,
          );
          if (completedChal == null) continue;
          int basePoints = completedChal.points ?? 0;

          // TIMER: Calculate points - 0 if failed, otherwise apply extension and hint adjustments
          // Quiz version only had: pts = calculateHintAdjustedPoints(basePoints, prevChal.hintsUsed);
          // Timer version has failed check + extension adjustment
          int pts;
          if (prevChal.failed == true) {
            pts = 0;
          } else {
            int extensionAdjustedPoints = calculateExtensionAdjustedPoints(
              basePoints,
              prevChal.extensionsUsed ?? 0,
            );
            pts = calculateHintAdjustedPoints(
              extensionAdjustedPoints,
              prevChal.hintsUsed,
            );
          }
          total_pts += pts;

          completedChallenges.add(
            Container(
              margin: EdgeInsets.only(left: 30, bottom: 10, right: 30),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/locationCompleted.svg',
                    fit: BoxFit.cover,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      completedChal.name ?? "",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    // TIMER: Show "0 points" if failed
                    prevChal.failed == true
                        ? "0 points"
                        : "+ " + pts.toString() + " points",
                    style: TextStyle(color: Colors.white, fontSize: 16.0),
                  ),
                ],
              ),
            ),
          );
        }

        // QUIZ: Fetch quiz points for journeys when on journey page and completed
        // Changed from Quiz's (isJourney && journeyCompleted) to (journeyPage && journeyCompleted)
        // because Timer version uses journeyPage state toggle
        if (journeyPage && journeyCompleted && !isLoadingQuizPoints) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchQuizPointsForJourney(
              apiClient,
              tracker.prevChallenges,
              eventModel,
            );
          });
        }

        // QUIZ: Determine quiz points to display
        // Changed from Quiz's isJourney to journeyPage to match Timer's state-based approach
        int displayQuizPoints = 0;
        if (journeyPage && journeyCompleted) {
          // For completed journey page: use accumulated quiz points from all challenges
          displayQuizPoints = totalQuizPoints;
        } else if (!journeyPage) {
          // For single challenge view: use quiz points specifically earned for THIS challenge
          displayQuizPoints = quizModel.getPointsForChallenge(challenge.id);
        }

        // MERGED: Calculate final total points (combining Timer + Quiz)
        // Timer had: extensionAdjusted + hintAdjusted (no quiz)
        // Quiz had:  hintAdjusted + displayQuizPoints (no extension)
        // Merged:    extensionAdjusted + hintAdjusted + displayQuizPoints
        int basePoints = challenge.points ?? 0;
        int extensionAdjustedPoints = calculateExtensionAdjustedPoints(
          basePoints,
          extensionsUsed,
        );
        int finalAdjustedPoints = calculateHintAdjustedPoints(
          extensionAdjustedPoints,
          tracker.prevChallenges.last.hintsUsed,
        );

        int finalTotalPoints = journeyPage
            ? total_pts + displayQuizPoints
            : finalAdjustedPoints + displayQuizPoints;

        return Scaffold(
          body: Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: SvgPicture.asset(
                  'assets/images/challenge-completed-bg.svg',
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.47,
                  left: 20,
                  right: 20,
                ),
                height: MediaQuery.of(context).size.height * 0.53,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        // TIMER: Uses journeyPage state for title
                        journeyPage
                            ? (journeyCompleted
                                ? "Journey Complete"
                                : "Journey in Progress!")
                            : 'Challenge Complete!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Only show description when not on completed journey page
                    if (!(journeyPage && journeyCompleted))
                      Container(
                        padding: EdgeInsets.only(bottom: 15),
                        child: Text(
                          challenge.description ?? "NO DESCRIPTION",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    // TIMER: Show LoadingBar when on journey page
                    if (journeyPage)
                      Container(
                        padding: EdgeInsets.only(left: 30, bottom: 10),
                        alignment: Alignment.centerLeft,
                        child: LoadingBar(
                          tracker.prevChallenges.length,
                          event?.challenges?.length ?? 0,
                        ),
                      ),
                    Container(
                      padding: EdgeInsets.only(left: 30, bottom: 10),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Points',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // TIMER: Single challenge view (not journey page)
                    if (!journeyPage) ...[
                      Container(
                        margin: EdgeInsets.only(
                          left: 30,
                          bottom: 10,
                          right: 30,
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/locationCompleted.svg',
                              fit: BoxFit.cover,
                            ),
                            Text(
                              "   Found Location",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            Text(
                              // TIMER: Shows extension-adjusted points
                              "+ " +
                                  extensionAdjustedPoints.toString() +
                                  " points",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // TIMER: Show extension penalty if any
                      if (extensionsUsed > 0)
                        Container(
                          margin: EdgeInsets.only(
                            left: 30,
                            bottom: 10,
                            right: 30,
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/timer_icon_purple.svg',
                                fit: BoxFit.cover,
                              ),
                              Text(
                                "   +${extensionsUsed * 5} Minutes",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              Text(
                                () {
                                  int penalty =
                                      basePoints - extensionAdjustedPoints;
                                  return "- $penalty points";
                                }(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // BOTH: Show hint penalty if any
                      if (tracker.prevChallenges.last.hintsUsed > 0)
                        Container(
                          margin: EdgeInsets.only(
                            left: 30,
                            bottom: 10,
                            right: 30,
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/hint.svg',
                                fit: BoxFit.cover,
                              ),
                              Text(
                                "   Used ${tracker.prevChallenges.last.hintsUsed} hint${tracker.prevChallenges.last.hintsUsed > 1 ? 's' : ''}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              Text(
                                () {
                                  int penalty = extensionAdjustedPoints -
                                      finalAdjustedPoints;
                                  return "- $penalty points";
                                }(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // QUIZ: Show quiz bonus for single challenge if any
                      if (displayQuizPoints > 0)
                        Container(
                          margin: EdgeInsets.only(
                            left: 30,
                            bottom: 10,
                            right: 30,
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/quiz.svg',
                                fit: BoxFit.cover,
                              ),
                              Text(
                                "   Quiz Bonus",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              Text(
                                "+ $displayQuizPoints points",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ] else ...[
                      // TIMER: Journey page view - show completed challenges list
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            ...completedChallenges,
                            // QUIZ: Show quiz bonus for journey if any (inside scroll view)
                            if (displayQuizPoints > 0)
                              Container(
                                margin: EdgeInsets.only(
                                  left: 30,
                                  bottom: 10,
                                  right: 30,
                                ),
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/quiz.svg',
                                      fit: BoxFit.cover,
                                    ),
                                    Text(
                                      "   Quiz Bonus",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Spacer(),
                                    Text(
                                      "+ $displayQuizPoints points",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 10),
                    // MERGED: Total points display
                    // Timer had: journeyPage ? total_pts : extensionAdjusted + hintAdjusted
                    // Quiz had:  "Total Points: $finalTotalPoints" (always same label)
                    // Merged: Different labels + includes quiz bonus
                    Text(
                      journeyPage
                          ? "Total Points: $finalTotalPoints"
                          : "Points Earned: $finalTotalPoints",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Only use Spacer for single challenge view (journey page has Expanded ListView)
                    if (!journeyPage) Spacer(),
                    // TIMER: Button logic with journeyPage state toggle
                    // Quiz version had simpler direct navigation without journeyPage toggle
                    journeyPage
                        ? Container(
                            alignment: Alignment.bottomCenter,
                            margin: EdgeInsets.only(
                              bottom: MediaQuery.sizeOf(context).height * 0.05,
                            ),
                            child: journeyCompleted
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryRed,
                                      padding: EdgeInsets.only(
                                        right: 15,
                                        left: 15,
                                        top: 10,
                                        bottom: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Return Home ",
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 21,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFFFFFFFF),
                                          ),
                                        ),
                                        SvgPicture.asset(
                                          "assets/icons/forwardcarrot.svg",
                                        ),
                                      ],
                                    ),
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BottomNavBar(),
                                        ),
                                      );
                                    },
                                  )
                                : Row(
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: EdgeInsets.only(
                                            right: 15,
                                            left: 15,
                                            top: 10,
                                            bottom: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: Colors.white,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () =>
                                            Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                BottomNavBar(),
                                          ),
                                        ),
                                        child: Text(
                                          "Leave",
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 20,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFFFFFFFF),
                                          ),
                                        ),
                                      ),
                                      Spacer(),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryRed,
                                          padding: EdgeInsets.only(
                                            right: 15,
                                            left: 15,
                                            top: 10,
                                            bottom: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () =>
                                            Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GameplayPage(),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "Next Challenge ",
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 20,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFFFFFFFF),
                                              ),
                                            ),
                                            SvgPicture.asset(
                                              "assets/icons/forwardcarrot.svg",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          )
                        : Container(
                            alignment: Alignment.bottomCenter,
                            margin: EdgeInsets.only(
                              bottom: MediaQuery.sizeOf(context).height * 0.05,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryRed,
                                padding: EdgeInsets.only(
                                  right: 15,
                                  left: 15,
                                  top: 10,
                                  bottom: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    // TIMER: Shows "Journey Progress" for journeys, "Return Home" for single challenges
                                    isJourney
                                        ? "Journey Progress "
                                        : "Return Home ",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 21,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                                  SvgPicture.asset(
                                    "assets/icons/forwardcarrot.svg",
                                  ),
                                ],
                              ),
                              onPressed: () {
                                // TIMER: Toggle to journey page or navigate home
                                if (isJourney) {
                                  journeyPage = true;
                                  setState(() {});
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BottomNavBar(),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
