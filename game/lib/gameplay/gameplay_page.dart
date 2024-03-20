import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:game/api/geopoint.dart';
import 'package:geolocator/geolocator.dart';
import 'package:game/model/challenge_model.dart';
import 'gameplay_map.dart';
import 'package:provider/provider.dart';
import 'package:game/progress_indicators/circular_progress_indicator.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

class GameplayPage extends StatefulWidget {
  final String eventId;

  const GameplayPage({Key? key, required this.eventId}) : super(key: key);

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
    return Consumer3<ChallengeModel, EventModel, TrackerModel>(
        builder: (context, challengeModel, eventModel, trackerModel, _) {
      var event = eventModel.getEventById(widget.eventId);
      var tracker = trackerModel.trackerByEventId(widget.eventId);

      if (tracker == null) {
        return CircularIndicator();
      }

      var challenge = challengeModel.getChallengeById(tracker.curChallengeId);

      if (challenge == null) {
        return Scaffold(
          body: Text("No challenge data"),
        );
      }

      GeoPoint targetLocation = GeoPoint(challenge.lat, challenge.long, 0);
      double awardingRadius = challenge.awardingRadius;

      return Scaffold(
        body: Column(
          children: [
            //SafeArea to avoid notch overlap
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
                                    },
                                    child: Row(children: [
                                      SvgPicture.asset(
                                          "assets/icons/backcarrot.svg"),
                                      Text('  Leave Journey',
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
                                  child: const Text('Challenge',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFFA4A4A4))),
                                ),
                              ]),
                          Container(
                            margin: EdgeInsets.only(top: 16.45, bottom: 11),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Find the Location of ${challenge.description}!",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                              padding: EdgeInsets.only(left: 18, right: 18),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      SvgPicture.asset(
                                          "assets/icons/locationpin.svg"),
                                      Text(' Arts Quad',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF835A7C)))
                                    ]),
                                    Row(children: [
                                      SvgPicture.asset(
                                          "assets/icons/feetpics.svg"),
                                      Text(
                                          ' ' +
                                              (currentLocation != null
                                                  ? (currentLocation!.distanceTo(
                                                              targetLocation) /
                                                          1609.34)
                                                      .toStringAsFixed(1)
                                                  : "0.0") +
                                              ' Miles Away',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF58B171)))
                                    ]),
                                    Row(children: [
                                      SvgPicture.asset(
                                          "assets/icons/bearcoins.svg"),
                                      Text(' 0/100',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFFFC737)))
                                    ]),
                                  ]))
                        ]))),
            Expanded(
              child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: GameplayMap(
                    targetLocation: targetLocation,
                    awardingRadius: awardingRadius,
                    description: challenge.description,
                    points: 100, // TODO: update after points is in backend
                  )),
            ),
          ],
        ),
      );
    });
  }
}
