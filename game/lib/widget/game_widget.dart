import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/geopoint.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
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

double calcCompletionProgress(
  double distance,
  double closeRadius,
  double completionRadius,
) {
  return max(
    0,
    1 - (distance - completionRadius) / (closeRadius - completionRadius),
  );
}

double calcCloseProgress(double distance, double closeRadius) {
  distance = distance / 1000;
  closeRadius = closeRadius / 1000;
  if (distance > 50) {
    distance = 50;
  }

  return pow(0.1, distance - closeRadius).toDouble();
}

class _GameWidgetState extends State<GameWidget> {
  final Widget _child;

  DateTime lastCheckTime = DateTime.now();
  double lastDistance = 0;

  _GameWidgetState(Widget child) : _child = child;
  @override
  Widget build(BuildContext context) {
    final serviceStream = Geolocator.getServiceStatusStream();

    return Consumer5<GroupModel, TrackerModel, ChallengeModel, EventModel,
        ApiClient>(
      builder: (
        builder,
        groupModel,
        trackerModel,
        challengeModel,
        eventModel,
        apiCient,
        child,
      ) {
        return StreamBuilder<ServiceStatus>(
          stream: serviceStream,
          builder: (context, service) {
            final posStream = Geolocator.getPositionStream(
              locationSettings: new LocationSettings(),
            );

            final serviceStatus = service.data;

            return StreamBuilder<Position>(
              stream: posStream,
              builder: ((context, snapshot) {
                final gameModel = GameModel();
                final evId = groupModel.curEventId;
                final ev = eventModel.getEventById(evId ?? "");
                final chalId = evId == null
                    ? null
                    : trackerModel.trackerByEventId(evId)?.curChallengeId;
                final curChallenge = chalId == null
                    ? null
                    : challengeModel.getChallengeById(chalId);
                final reqMembers = ev?.requiredMembers ?? 0;
                final requiredSizeMet =
                    groupModel.members.length == reqMembers || reqMembers < 0;

                gameModel.hasConnection = apiCient.serverApi != null;
                if (curChallenge != null) {
                  gameModel.challengeId = curChallenge.id;
                  gameModel.description = curChallenge.description ?? "";
                  gameModel.name = curChallenge.name ?? "";
                  gameModel.imageUrl = curChallenge.imageUrl ??
                      "https://upload.wikimedia.org/wikipedia/commons/b/b1/Missing-image-232x150.png";
                }

                if (serviceStatus == ServiceStatus.disabled ||
                    !requiredSizeMet) {
                  gameModel.walkingTime = !requiredSizeMet
                      ? (reqMembers == 1
                          ? "1 member required"
                          : reqMembers.toString() + " members required")
                      : "Location Disabled";
                  gameModel.closeProgress = -1;
                  gameModel.completionProgress = -1;
                }

                if (snapshot.data != null &&
                    curChallenge != null &&
                    requiredSizeMet) {
                  final chalLoc = GeoPoint(
                    curChallenge.latF ?? 0,
                    curChallenge.longF ?? 0,
                    0,
                  );
                  final location = GeoPoint(
                    snapshot.data!.latitude,
                    snapshot.data!.longitude,
                    snapshot.data!.heading,
                  );
                  final distance = location.distanceTo(chalLoc);

                  gameModel.walkingTime =
                      (distance / 80).ceil().toString() + " min";
                  gameModel.completionProgress = calcCompletionProgress(
                    distance,
                    curChallenge.closeRadiusF ?? 0,
                    curChallenge.awardingRadiusF ?? 0,
                  );
                  gameModel.closeProgress = calcCloseProgress(
                    distance,
                    curChallenge.closeRadiusF ?? 0,
                  );
                  gameModel.directionDistance = lastDistance - distance;
                  gameModel.withinCompletionRadius =
                      distance < (curChallenge.awardingRadiusF ?? 0);
                  gameModel.withinCloseRadius =
                      distance < (curChallenge.closeRadiusF ?? 0);

                  if (DateTime.now().difference(lastCheckTime).inSeconds > 10) {
                    lastDistance = distance;
                    lastCheckTime = DateTime.now();
                  }
                }

                return Provider.value(value: gameModel, child: _child);
              }),
            );
          },
        );
      },
    );
  }
}
