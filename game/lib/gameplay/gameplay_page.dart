import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/api/geopoint.dart';
import 'package:game/navigation_page/bottom_navbar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:game/model/challenge_model.dart';
import 'gameplay_map.dart';
import 'package:provider/provider.dart';
import 'package:game/utils/utility_functions.dart';

import 'package:game/api/game_client_dto.dart';
import 'package:game/progress_indicators/circular_progress_indicator.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

class GameplayPage extends StatefulWidget {
  const GameplayPage({Key? key}) : super(key: key);

  @override
  State<GameplayPage> createState() => _GameplayPageState();
}

class _GameplayPageState extends State<GameplayPage> {
  // User is by default centered around some location on Cornell's campus.
  // User should only be at these coords briefly before map is moved to user's
  // current location.
  final GeoPoint _center = GeoPoint(42.447, -76.4875, 0);

  // User's current location will fall back to _center when current location
  // cannot be found
  GeoPoint? currentLocation;

  late StreamSubscription<Position> positionStream;

  @override
  void initState() {
    startPositionStream();
    super.initState();
  }

  @override
  void dispose() {
    positionStream.cancel();
    super.dispose();
  }

  /**
   * Starts the user's current location streaming upon state initialization
   * Sets the camera to center on user's location by default
   */
  void startPositionStream() async {
    GeoPoint.current().then(
      (location) {
        currentLocation = location;
      },
    );

    positionStream = Geolocator.getPositionStream(
            locationSettings: GeoPoint.getLocationSettings())
        .listen((Position? newPos) {
      // prints user coordinates - useful for debugging
      // print(newPos == null
      //     ? 'Unknown'
      //     : '${newPos.latitude.toString()}, ${newPos.longitude.toString()}');

      currentLocation = newPos == null
          ? _center
          : GeoPoint(newPos.latitude, newPos.longitude, newPos.heading);

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer5<ChallengeModel, EventModel, TrackerModel, ApiClient,
            GroupModel>(
        builder: (context, challengeModel, eventModel, trackerModel, apiClient,
            groupModel, _) {
      var eventId = groupModel.curEventId;
      // print(eventId);
      var event = eventModel.getEventById(eventId ?? "");
      var tracker = trackerModel.trackerByEventId(eventId ?? "");
      if (tracker == null) {
        return CircularIndicator();
      }

      var challenge = challengeModel.getChallengeById(
          tracker.curChallengeId ?? tracker.prevChallenges.last.challengeId);

      if (challenge == null) {
        return Scaffold(
          body: Text("No challenge data"),
        );
      }

      GeoPoint? targetLocation;
      if (challenge.latF != null && challenge.longF != null) {
        targetLocation = GeoPoint(challenge.latF!, challenge.longF!, 0);
      }
      double awardingRadius = challenge.awardingRadiusF ?? 0;
      int hintsUsed = tracker.hintsUsed;

      double sectionSeperation = MediaQuery.of(context).size.width * 0.05;

      return Scaffold(
        body: Column(
          children: [
            SafeArea(
                bottom: false,
                child: Container(
                    padding: EdgeInsets.only(left: 39, right: 39, bottom: 10),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                    style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size(50, 30),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        alignment: Alignment.centerLeft,
                                        foregroundColor: Colors.grey),
                                    onPressed: () {
                                      // Left button action
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                BottomNavBar()),
                                      );
                                    },
                                    child: Row(children: [
                                      SvgPicture.asset(
                                          "assets/icons/backcarrot.svg"),
                                      Text(
                                          '  Leave ' +
                                              (event!.challenges!.length > 1
                                                  ? "Journey"
                                                  : "Challenge"),
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF835A7C)))
                                    ])),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F1F1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(15.0),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 8.0),
                                  child: Text(
                                      (event.challenges!.length > 1
                                          ? "Journey"
                                          : "Challenge"),
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFFA4A4A4))),
                                ),
                              ]),
                          Container(
                            margin: EdgeInsets.only(top: 16.45, bottom: 11),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              challenge.description ?? "NO DESCRIPTION",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                              child: Row(children: [
                            // Location section - auto-scaling text
                            Expanded(
                              flex: 3,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SvgPicture.asset(
                                      "assets/icons/locationpin.svg"),
                                  Flexible(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        String text = ' ' +
                                            (abbrevLocation[
                                                    challenge.location] ??
                                                "");
                                        return FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(text,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF835A7C))),
                                        );
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(width: sectionSeperation),
                            // Distance section - auto-scaling text
                            Expanded(
                              flex: 3,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SvgPicture.asset("assets/icons/feetpics.svg"),
                                  Flexible(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        String text = ' ' +
                                            (currentLocation != null &&
                                                    targetLocation != null
                                                ? (currentLocation!.distanceTo(
                                                            targetLocation) /
                                                        1609.34)
                                                    .toStringAsFixed(1)
                                                : "?.?") +
                                            ' Mi Away';
                                        return FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(text,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF58B171))),
                                        );
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(width: sectionSeperation),
                            // Points section - auto-scaling text
                            Expanded(
                              flex: 3,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SvgPicture.asset(
                                      "assets/icons/bearcoins.svg"),
                                  Flexible(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        int basePoints = challenge.points ?? 0;
                                        int adjustedPoints =
                                            calculateHintAdjustedPoints(
                                                basePoints, hintsUsed);

                                        String text = ' ' +
                                            (hintsUsed > 0
                                                ? adjustedPoints.toString() +
                                                    '/' +
                                                    basePoints.toString()
                                                : basePoints.toString()) +
                                            " PTS";
                                        return FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(text,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFFC17E19))),
                                        );
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ]))
                        ]))),
            Expanded(
              child: Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: GameplayMap(
                    challengeId: challenge.id,
                    targetLocation: (targetLocation ?? _center),
                    awardingRadius: awardingRadius,
                    points: challenge.points ?? 0,
                    startingHintsUsed: hintsUsed,
                  )),
            ),
          ],
        ),
      );
    });
  }
}
