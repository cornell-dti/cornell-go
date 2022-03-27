import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/geopoint.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/game_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class GameWidget extends StatefulWidget {
  final Widget _child;
  const GameWidget({Key? key, required Widget child})
      : _child = child,
        super(key: key);

  @override
  _GameWidgetState createState() => _GameWidgetState(_child);
}

double calcCompletionProgress(double distance, double completionRadius) {
  return 1 - distance / completionRadius;
}

double calcCloseProgress(double distance, double closeRadius) {
  return pow(1.5, distance - closeRadius).toDouble();
}

class _GameWidgetState extends State<GameWidget> {
  final Widget _child;
  _GameWidgetState(Widget child) : _child = child;
  @override
  Widget build(BuildContext context) {
    final posStream =
        Geolocator.getPositionStream(locationSettings: new LocationSettings());

    return Consumer4<GroupModel, TrackerModel, ChallengeModel, ApiClient>(
        builder: (builder, groupModel, trackerModel, challengeModel, apiCient,
            child) {
      return StreamBuilder<Position>(
          stream: posStream,
          builder: ((context, snapshot) {
            final gameModel = GameModel();
            final evId = groupModel.curEventId;
            final chalId = evId == null
                ? null
                : trackerModel.trackerByEventId(evId)?.curChallengeId;
            final curChallenge =
                chalId == null ? null : challengeModel.getChallengeById(chalId);

            gameModel.hasConnection = apiCient.serverApi != null;
            if (curChallenge != null) {
              gameModel.description = curChallenge.description;
              gameModel.name = curChallenge.name;
              gameModel.imageUrl = curChallenge.imageUrl;
            }

            if (snapshot.data != null && curChallenge != null) {
              final chalLoc = GeoPoint(curChallenge.lat, curChallenge.long);
              final location =
                  GeoPoint(snapshot.data!.latitude, snapshot.data!.longitude);
              final heading = snapshot.data!.heading;

              final distance = location.distanceTo(chalLoc);
              final bearing = location.bearingTo(chalLoc);

              gameModel.walkingTime =
                  (distance / 80).ceil().toString() + " min";
              gameModel.completionProgress =
                  calcCompletionProgress(distance, curChallenge.awardingRadius);
              gameModel.closeProgress =
                  calcCloseProgress(distance, curChallenge.closeRadius);
              gameModel.directionDistance = (heading - bearing - 180) / 180;
              gameModel.withinCompletionRadius =
                  distance < curChallenge.awardingRadius;
              gameModel.withinCloseRadius = distance < curChallenge.closeRadius;
            }

            return Provider.value(value: gameModel, child: _child);
          }));
    });
  }
}
