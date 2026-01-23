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
import 'package:game/utils/utility_functions.dart';
import 'dart:math';

import 'package:flutter_svg/flutter_svg.dart';

/**
 * Displays Challenge Failed page
 */
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

class ChallengeFailedPage extends StatefulWidget {
  final String challengeId;
  const ChallengeFailedPage({
    Key? key,
    required this.challengeId,
  }) : super(key: key);

  @override
  State<ChallengeFailedPage> createState() => _ChallengeFailedState();
}

class _ChallengeFailedState extends State<ChallengeFailedPage>
    with SingleTickerProviderStateMixin {
  bool journeyPage = false;
  bool journeyCompleted = false;
  late AnimationController _lightningController;
  late Animation<double> _lightningAnimation;
  bool _hasRequestedTracker = false;

  @override
  void initState() {
    super.initState();
    // Create animation controller for lightning flash (flash twice over 2 seconds)
    _lightningController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    // Create animation that goes from 0 to 1, with two flashes
    _lightningAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lightningController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animation when page loads
    _lightningController.forward();

    // Request fresh tracker data after first frame
    // This ensures we have the latest prevChallenges (including the failed one)
    // and curChallengeId (already updated to next challenge by backend)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestFreshTrackerData();
    });
  }

  void _requestFreshTrackerData() {
    if (_hasRequestedTracker) return;
    _hasRequestedTracker = true;

    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final groupModel = Provider.of<GroupModel>(context, listen: false);
    final eventId = groupModel.curEventId;
    if (eventId != null) {
      apiClient.serverApi?.requestEventTrackerData(
          RequestEventTrackerDataDto(trackedEvents: [eventId]));
    }
  }

  @override
  void dispose() {
    _lightningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer5<ChallengeModel, EventModel, TrackerModel, ApiClient,
            GroupModel>(
        builder: (context, challengeModel, eventModel, trackerModel, apiClient,
            groupModel, _) {
      var eventId = groupModel.curEventId;
      var event = eventModel.getEventById(eventId ?? "");
      var tracker = trackerModel.trackerByEventId(eventId ?? "");
      if (tracker == null) {
        return CircularIndicator();
      }

      // If this event is a journey
      if ((event?.challenges?.length ?? 0) > 1)
        // Determine whether the journey is done
        journeyCompleted =
            tracker.prevChallenges.length == (event?.challenges?.length ?? 0);

      // Use the failed challengeId instead of last completed challenge since challenge failed
      var challenge = challengeModel.getChallengeById(widget.challengeId);

      if (challenge == null) {
        return Scaffold(
          body: Text("No challenge data"),
        );
      }

      // Get hints used for the failed challenge
      int failedChallengeHintsUsed = 0;
      if (tracker.curChallengeId == widget.challengeId) {
        failedChallengeHintsUsed = tracker.hintsUsed;
      }

      // Build list of completed challenge text fields to display later
      var total_pts = 0;
      List<Widget> completedChallenges = [];
      for (PrevChallengeDto prevChal in tracker.prevChallenges) {
        var completedChal =
            challengeModel.getChallengeById(prevChal.challengeId);
        if (completedChal == null) continue;

        // Calculate points: 0 if failed, otherwise apply extension and hint adjustments
        int pts;
        if (prevChal.failed == true) {
          pts = 0;
        } else {
          int extensionsUsed = prevChal.extensionsUsed ?? 0;
          int extensionAdjustedPoints = calculateExtensionAdjustedPoints(
              completedChal.points ?? 0, extensionsUsed);
          pts = calculateHintAdjustedPoints(
              extensionAdjustedPoints, prevChal.hintsUsed);
        }
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
                  prevChal.failed == true
                      ? "0 points"
                      : "+ " + pts.toString() + " points",
                  style: TextStyle(color: Colors.white, fontSize: 16.0),
                ),
              ],
            )));
      }

      return Scaffold(
          body: Stack(children: [
        // Black to gray gradient background for sky
        Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  Color(0xFFD5D5D5),
                ],
              ),
            )),
        Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: SvgPicture.asset(
              'assets/images/challenge-failed-bg.svg',
              fit: BoxFit.cover,
            )),
        /** Animated lightning bolts overlay
         * - Two lightning bolts appear next to the original lightning bolts and flash twice over two seconds
         * - both flashes are 0.45 seconds long; the opacity changes depending on the time elapsed
         */
        AnimatedBuilder(
          animation: _lightningAnimation,
          builder: (context, child) {
            double opacity = 0.0;
            double progress = _lightningAnimation.value;

            // First flash
            if (progress < 0.45) {
              double flash1Progress = progress / 0.45;
              opacity = flash1Progress < 0.5
                  ? flash1Progress * 2 // Fade in
                  : (1.0 - flash1Progress) * 2; // Fade out
            }
            // Second flash
            else if (progress >= 0.55) {
              double flash2Progress = (progress - 0.55) / 0.45;
              opacity = flash2Progress < 0.5
                  ? flash2Progress * 2
                  : (1.0 - flash2Progress) * 2;
            }

            return Opacity(
              opacity: opacity,
              child: Stack(
                children: [
                  // First lightning bolt (positioned at x=271, y=89 in 393x852 viewBox)
                  Positioned(
                    left: MediaQuery.of(context).size.width * (271 / 393),
                    top: MediaQuery.of(context).size.height * (89 / 852),
                    child: SvgPicture.asset(
                      'assets/images/lightning_1.svg',
                      width: 65,
                      height: 197,
                    ),
                  ),
                  // Second lightning bolt (positioned at x=105, y=135 in 393x852 viewBox)
                  Positioned(
                    left: MediaQuery.of(context).size.width * (105 / 393),
                    top: MediaQuery.of(context).size.height * (135 / 852),
                    child: SvgPicture.asset(
                      'assets/images/lightning_2.svg',
                      width: 39,
                      height: 118,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Container(
            margin: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.47,
                left: 20,
                right: 20),
            height: MediaQuery.of(context).size.height * 0.53,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    journeyPage
                        ? (journeyCompleted
                            ? "Journey Complete"
                            : "Journey in Progress!")
                        : 'Challenge Failed!',
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
                    "You were unable to find " +
                        (challenge.name ?? "this challenge") +
                        ".",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (journeyPage)
                  Container(
                      padding: EdgeInsets.only(left: 30, bottom: 10),
                      alignment: Alignment.centerLeft,
                      child: LoadingBar(tracker.prevChallenges.length,
                          event?.challenges?.length ?? 0)),
                if (!journeyPage) ...[
                  // Show hint penalty only if hints were used for the failed challenge
                  if (failedChallengeHintsUsed > 0)
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
                              "   Used $failedChallengeHintsUsed hint${failedChallengeHintsUsed > 1 ? 's' : ''}",
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
                                    calculateHintAdjustedPoints(
                                        basePoints, failedChallengeHintsUsed);
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
                ] else
                  Container(
                      height: MediaQuery.sizeOf(context).height * 0.15,
                      child: ListView(
                          padding: EdgeInsets.zero,
                          children: completedChallenges)),
                SizedBox(height: 10),
                Text(
                  journeyPage
                      ? "Points Earned: " + total_pts.toString()
                      : "Points Earned: " + total_pts.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                journeyPage
                    ? Container(
                        alignment: Alignment.bottomCenter,
                        margin: EdgeInsets.only(
                            bottom: MediaQuery.sizeOf(context).height * 0.05),
                        child: journeyCompleted
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color.fromARGB(255, 237, 86, 86),
                                  padding: EdgeInsets.only(
                                      right: 15, left: 15, top: 10, bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        10), // button's shape,
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
                                            color: Color(0xFFFFFFFF)),
                                      ),
                                      SvgPicture.asset(
                                          "assets/icons/forwardcarrot.svg")
                                    ]),
                                onPressed: () {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              BottomNavBar()));
                                },
                              )
                            : Row(
                                children: [
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Color.fromARGB(0, 255, 255, 255),
                                        shadowColor:
                                            Color.fromARGB(0, 255, 255, 255),
                                        padding: EdgeInsets.only(
                                            right: 15,
                                            left: 15,
                                            top: 10,
                                            bottom: 10),
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(color: Colors.white),
                                          borderRadius: BorderRadius.circular(
                                              10), // button's shape,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    BottomNavBar()));
                                      },
                                      child: Text(
                                        "Leave",
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 20,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFFFFFFFF)),
                                      )),
                                  Spacer(),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Color.fromARGB(255, 237, 86, 86),
                                      padding: EdgeInsets.only(
                                          right: 15,
                                          left: 15,
                                          top: 10,
                                          bottom: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            10), // button's shape,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  GameplayPage()));
                                    },
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "Next Challenge ",
                                            style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 20,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFFFFFFFF)),
                                          ),
                                          SvgPicture.asset(
                                              "assets/icons/forwardcarrot.svg")
                                        ]),
                                  ),
                                ],
                              ),
                      )
                    : Container(
                        alignment: Alignment.bottomCenter,
                        margin: EdgeInsets.only(
                            bottom: MediaQuery.sizeOf(context).height * 0.05),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 237, 86, 86),
                            padding: EdgeInsets.only(
                                right: 15, left: 15, top: 10, bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // button's shape,
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(
                              ((event?.challenges?.length ?? 0) > 1)
                                  ? "Journey Progress "
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
                            if ((event?.challenges?.length ?? 0) > 1) {
                              journeyPage = true;
                              setState(() {});
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
