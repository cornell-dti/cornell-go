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
import 'package:game/model/group_model.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/quiz_model.dart';
import 'package:game/utils/utility_functions.dart';
import 'dart:math';
import 'dart:async';

import 'package:flutter_svg/flutter_svg.dart';

class LoadingBar extends StatelessWidget {
  final int totalTasks;
  final int tasksFinished;

  const LoadingBar(
    this.tasksFinished,
    this.totalTasks,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: MediaQuery.sizeOf(context).width * 0.66,
            height: 20,
            child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(children: [
                Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: new BoxDecoration(
                      color: Color.fromARGB(255, 241, 241, 241),
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
                      color: Color.fromARGB(197, 237, 86, 86),
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
                      0),
                  margin: EdgeInsets.only(left: 8, top: 3),
                  alignment: Alignment.centerLeft,
                  decoration: new BoxDecoration(
                    color: Color(0x99F3C6C6),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                ),
              ]);
            })),
        Expanded(
            flex: 2,
            child: Row(children: [
              Text(" "),
              SvgPicture.asset("assets/icons/pin.svg"),
              Text(
                " " + tasksFinished.toString() + "/" + totalTasks.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              )
            ]))
      ],
    );
  }
}

class ChallengeCompletedPage extends StatefulWidget {
  final String challengeId;
  const ChallengeCompletedPage({
    Key? key,
    required this.challengeId,
  }) : super(key: key);

  @override
  State<ChallengeCompletedPage> createState() => _ChallengeCompletedState();
}

class _ChallengeCompletedState extends State<ChallengeCompletedPage> {
  bool journeyCompleted = false;
  int totalQuizPoints = 0;
  bool isLoadingQuizPoints = false;
  Map<String, int> quizPointsByChallenge = {};

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchQuizPointsForJourney(ApiClient apiClient,
      List<PrevChallengeDto> prevChallenges, EventModel eventModel) async {
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
    final subscription =
        apiClient.clientApi.quizProgressStream.listen((progress) {
      if (mounted) {
        setState(() {
          if (!quizPointsByChallenge.containsKey(progress.challengeId)) {
            quizPointsByChallenge[progress.challengeId] =
                progress.totalPointsEarned;
            totalQuizPoints = quizPointsByChallenge.values
                .fold(0, (sum, points) => sum + points);
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
      apiClient.serverApi?.getQuizProgress(prevChallenge.challengeId);
    }

    try {
      await completer.future.timeout(
        Duration(seconds: 2),
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
    return Consumer6<ChallengeModel, EventModel, TrackerModel, ApiClient,
            GroupModel, QuizModel>(
        builder: (context, challengeModel, eventModel, trackerModel, apiClient,
            groupModel, quizModel, _) {
      var eventId = groupModel.curEventId;
      var event = eventModel.getEventById(eventId ?? "");
      var tracker = trackerModel.trackerByEventId(eventId ?? "");
      
      if (tracker == null || tracker.prevChallenges.length == 0) {
        return CircularIndicator();
      }

      final isJourney = (event?.challenges?.length ?? 0) > 1;
      
      if (isJourney) {
        journeyCompleted =
            tracker.prevChallenges.length == (event?.challenges?.length ?? 0);
      }

      var challenge = challengeModel
          .getChallengeById(tracker.prevChallenges.last.challengeId);

      if (challenge == null) {
        return Scaffold(
          body: Text("No challenge data"),
        );
      }

      // Build list of completed challenge text fields for journeys
      var total_pts = 0;
      List<Widget> completedChallenges = [];
      
      for (PrevChallengeDto prevChal in tracker.prevChallenges) {
        var completedChal =
            challengeModel.getChallengeById(prevChal.challengeId);
        if (completedChal == null) continue;

        int basePoints = completedChal.points ?? 0;
        var pts = calculateHintAdjustedPoints(basePoints, prevChal.hintsUsed);
        total_pts += pts;

        completedChallenges.add(Container(
            margin: EdgeInsets.only(left: 30, bottom: 10, right: 30),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/locationCompleted.svg',
                  fit: BoxFit.cover,
                ),
                Text(
                  "   " + (completedChal.name ?? ""),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Text(
                  pts.toString(),
                  style: TextStyle(color: Colors.white, fontSize: 16.0),
                ),
              ],
            )));
      }

      // Fetch quiz points for journeys when completed
      if (isJourney && journeyCompleted && !isLoadingQuizPoints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchQuizPointsForJourney(
              apiClient, tracker.prevChallenges, eventModel);
        });
      }

      // Determine quiz points to display
      int displayQuizPoints = 0;
      
      if (isJourney && journeyCompleted) {
        // For completed journey: use accumulated quiz points from all challenges
        displayQuizPoints = totalQuizPoints;
      } else if (!isJourney) {
        // For single challenge: use quiz points specifically earned for THIS challenge
        displayQuizPoints = quizModel.getPointsForChallenge(challenge.id);
        
        // Debug: print quiz state
        print('🎯 Single Challenge Quiz Debug:');
        print('  currentChallengeId: ${quizModel.currentChallengeId}');
        print('  challenge.id: ${challenge.id}');
        print('  points for this challenge: ${quizModel.getPointsForChallenge(challenge.id)}');
        print('  totalPointsEarned (all): ${quizModel.totalPointsEarned}');
        print('  displayQuizPoints: $displayQuizPoints');
      }

      // Calculate final total points
      int basePoints = challenge.points ?? 0;
      int hintAdjustedPoints = calculateHintAdjustedPoints(
          basePoints, tracker.prevChallenges.last.hintsUsed);
      
      int finalTotalPoints = isJourney && journeyCompleted
          ? total_pts + displayQuizPoints
          : hintAdjustedPoints + displayQuizPoints;

      return Scaffold(
          body: Stack(children: [
        Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: SvgPicture.asset(
              'assets/images/challenge-completed-bg.svg',
              fit: BoxFit.cover,
            )),
        Container(
            margin: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.47,
                left: 20,
                right: 20),
            height: MediaQuery.of(context).size.height * 0.53,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    isJourney
                        ? (journeyCompleted
                            ? "Journey Complete"
                            : "Challenge Complete!")
                        : 'Challenge Complete!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(bottom: 15),
                  child: Text(
                    challenge.description ?? "NO DESCRIPTION",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Progress bar for journeys
                if (isJourney)
                  Container(
                    padding: EdgeInsets.only(left: 30, right: 30, bottom: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 22,
                            child: LayoutBuilder(
                              builder: (BuildContext context,
                                  BoxConstraints constraints) {
                                final totalChallenges =
                                    event?.challenges?.length ?? 0;
                                final completedChallenges =
                                    tracker.prevChallenges.length;
                                final progress = totalChallenges > 0
                                    ? completedChallenges / totalChallenges
                                    : 0.0;

                                return Stack(children: [
                                  // Background
                                  Container(
                                    width: constraints.maxWidth,
                                    height: constraints.maxHeight,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            Color.fromARGB(255, 241, 241, 241),
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(16.0)),
                                      ),
                                    ),
                                  ),
                                  // Progress fill
                                  Container(
                                    width: progress * constraints.maxWidth,
                                    height: constraints.maxHeight,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color.fromARGB(230, 237, 86, 86),
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(16.0)),
                                      ),
                                    ),
                                  ),
                                  // Inner highlight
                                  Container(
                                    height: 5,
                                    width: max(
                                        progress * constraints.maxWidth - 16,
                                        0),
                                    margin: EdgeInsets.only(left: 8, top: 3),
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(153, 243, 198, 198),
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(5.0)),
                                    ),
                                  ),
                                ]);
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        SvgPicture.asset("assets/icons/pin.svg"),
                        SizedBox(width: 5),
                        Text(
                          "${tracker.prevChallenges.length}/${event?.challenges?.length ?? 0}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: EdgeInsets.only(left: 30, bottom: 10),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Points',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Content area
                if (isJourney && journeyCompleted) ...[
                  // Scrollable list for completed journey
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...completedChallenges,
                          // Show quiz points breakdown if any challenges had quizzes
                          if (displayQuizPoints > 0)
                            Container(
                                margin: EdgeInsets.only(
                                    left: 30, bottom: 10, right: 30),
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
                                      "+ $displayQuizPoints",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ],
                                )),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Single challenge or incomplete journey
                  Container(
                      margin: EdgeInsets.only(left: 30, bottom: 10, right: 30),
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
                            "+ ${challenge.points ?? 0}",
                            style:
                                TextStyle(color: Colors.white, fontSize: 16.0),
                          ),
                        ],
                      )),
                  if (tracker.prevChallenges.last.hintsUsed > 0)
                    Container(
                        margin:
                            EdgeInsets.only(left: 30, bottom: 10, right: 30),
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
                                int basePoints = challenge.points ?? 0;
                                int adjustedPoints =
                                    calculateHintAdjustedPoints(basePoints,
                                        tracker.prevChallenges.last.hintsUsed);
                                int penalty = basePoints - adjustedPoints;
                                return "- $penalty points";
                              }(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                              ),
                            ),
                          ],
                        )),
                  // Show quiz points for single challenge if quiz was completed correctly
                  if (displayQuizPoints > 0)
                    Container(
                        margin:
                            EdgeInsets.only(left: 30, bottom: 10, right: 30),
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
                              "+ $displayQuizPoints",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                              ),
                            ),
                          ],
                        )),
                ],
                // Total points section
                SizedBox(height: 10),
                Text(
                  "Total Points: $finalTotalPoints",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Container(
                  alignment: Alignment.bottomCenter,
                  margin: EdgeInsets.only(
                      bottom: MediaQuery.sizeOf(context).height * 0.05),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 237, 86, 86),
                      padding: EdgeInsets.only(
                          right: 15, left: 15, top: 10, bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        isJourney
                            ? (journeyCompleted
                                ? "Return Home "
                                : "Next Challenge ")
                            : "Return Home ",
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 21,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFFFFFFF)),
                      ),
                      SvgPicture.asset("assets/icons/forwardcarrot.svg")
                    ]),
                    onPressed: () {
                      if (isJourney) {
                        if (journeyCompleted) {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BottomNavBar()));
                        } else {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GameplayPage()));
                        }
                      } else {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BottomNavBar()));
                      }
                    },
                  ),
                ),
              ],
            )),
      ]));
    });
  }
}
