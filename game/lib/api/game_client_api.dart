import 'dart:async';

import 'package:game/api/game_client_dto.dart';
import 'package:socket_io_client/socket_io_client.dart';

class GameClientApi {
  final _updateUserDataController = StreamController<UpdateUserDataDto>();
  get updateUserDataStream => _updateUserDataController.stream;

  final _userRewardedController = StreamController<UserRewardedDto>();
  get userRewardedStream => _userRewardedController.stream;

  final _invalidateDataController = StreamController<InvalidateDataDto>();
  get invalidateDataStream => _invalidateDataController.stream;

  final _updateRewardDataController = StreamController<UpdateRewardDataDto>();
  get updateRewardDataStream => _updateRewardDataController.stream;

  final _updateEventDataController =
      StreamController<UpdateEventDataEventDto>();
  get updateEventDataStream => _updateEventDataController.stream;

  final _updateLeaderDataController = StreamController<UpdateLeaderDataDto>();
  get updateLeaderDataStream => _updateLeaderDataController.stream;

  final _updateGroupDataController = StreamController<UpdateGroupDataDto>();
  get updateGroupDataStream => _updateGroupDataController.stream;

  final _updateEventTrackerDataController = StreamController<int>();
  get updateEventTrackerDataStream => _updateEventTrackerDataController.stream;

  final _updateChallengeDataController =
      StreamController<UpdateChallengeDataDto>();
  get updateChallengeDataStream => _updateChallengeDataController.stream;

  final _reconnectedController = StreamController<Null>();
  get reconnectedStream => _reconnectedController.stream;

  final _reconnectingController = StreamController<Null>();
  get reconnectingStream => _reconnectingController.stream;

  void connectSocket(Socket sock) {
    sock.onReconnect((data) => _reconnectingController.add(null));
    sock.onReconnecting((data) => _reconnectedController.add(null));
    sock.on("updateUserData", (data) => _updateUserDataController.add(data));
    sock.on("userRewarded", (data) => _userRewardedController.add(data));
    sock.on("invalidateData", (data) => _invalidateDataController.add(data));
    sock.on(
        "updateRewardData", (data) => _updateRewardDataController.add(data));
    sock.on("updateEventData", (data) => _updateEventDataController.add(data));
    sock.on(
        "updateLeaderData", (data) => _updateLeaderDataController.add(data));
    sock.on("updateGroupData", (data) => _updateGroupDataController.add(data));
    sock.on("updateEventTrackerData",
        (data) => _updateEventTrackerDataController.add(data));
    sock.on("updateChallengeData",
        (data) => _updateChallengeDataController.add(data));
  }

  GameClientApi() {}
}
