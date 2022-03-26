import 'dart:async';

import 'package:game/api/game_client_dto.dart';
import 'package:socket_io_client/socket_io_client.dart';

class GameClientApi {
  final _updateUserDataController =
      StreamController<UpdateUserDataDto>.broadcast(sync: true);
  Stream<UpdateUserDataDto> get updateUserDataStream =>
      _updateUserDataController.stream;

  final _userRewardedController =
      StreamController<UserRewardedDto>.broadcast(sync: true);
  Stream<UserRewardedDto> get userRewardedStream =>
      _userRewardedController.stream;

  final _invalidateDataController =
      StreamController<InvalidateDataDto>.broadcast(sync: true);
  Stream<InvalidateDataDto> get invalidateDataStream =>
      _invalidateDataController.stream;

  final _updateRewardDataController =
      StreamController<UpdateRewardDataDto>.broadcast(sync: true);
  Stream<UpdateRewardDataDto> get updateRewardDataStream =>
      _updateRewardDataController.stream;

  final _updateEventDataController =
      StreamController<UpdateEventDataDto>.broadcast(sync: true);
  Stream<UpdateEventDataDto> get updateEventDataStream =>
      _updateEventDataController.stream;

  final _updateLeaderDataController =
      StreamController<UpdateLeaderDataDto>.broadcast(sync: true);
  Stream<UpdateLeaderDataDto> get updateLeaderDataStream =>
      _updateLeaderDataController.stream;

  final _updateGroupDataController =
      StreamController<UpdateGroupDataDto>.broadcast(sync: true);
  Stream<UpdateGroupDataDto> get updateGroupDataStream =>
      _updateGroupDataController.stream;

  final _updateEventTrackerDataController =
      StreamController<UpdateEventTrackerDataDto>.broadcast(sync: true);
  Stream<UpdateEventTrackerDataDto> get updateEventTrackerDataStream =>
      _updateEventTrackerDataController.stream;

  final _updateChallengeDataController =
      StreamController<UpdateChallengeDataDto>.broadcast(sync: true);
  Stream<UpdateChallengeDataDto> get updateChallengeDataStream =>
      _updateChallengeDataController.stream;

  final _reconnectedController = StreamController<Null>.broadcast(sync: true);
  Stream<Null> get reconnectedStream => _reconnectedController.stream;

  final _reconnectingController = StreamController<Null>.broadcast(sync: true);
  Stream<Null> get reconnectingStream => _reconnectingController.stream;

  final _connectedController = StreamController<Null>.broadcast(sync: true);
  Stream<Null> get connectedStream => _connectedController.stream;

  void connectSocket(Socket sock) {
    sock.onReconnect((data) => _reconnectingController.add(null));
    sock.onReconnecting((data) => _reconnectedController.add(null));
    sock.on(
        "updateUserData",
        (data) =>
            _updateUserDataController.add(UpdateUserDataDto.fromJson(data)));
    sock.on("userRewarded",
        (data) => _userRewardedController.add(UserRewardedDto.fromJson(data)));
    sock.on(
        "invalidateData",
        (data) =>
            _invalidateDataController.add(InvalidateDataDto.fromJson(data)));
    sock.on(
        "updateRewardData",
        (data) => _updateRewardDataController
            .add(UpdateRewardDataDto.fromJson(data)));
    sock.on(
        "updateEventData",
        (data) =>
            _updateEventDataController.add(UpdateEventDataDto.fromJson(data)));
    sock.on(
        "updateLeaderData",
        (data) => _updateLeaderDataController
            .add(UpdateLeaderDataDto.fromJson(data)));
    sock.on(
        "updateGroupData",
        (data) =>
            _updateGroupDataController.add(UpdateGroupDataDto.fromJson(data)));
    sock.on(
        "updateEventTrackerData",
        (data) => _updateEventTrackerDataController
            .add(UpdateEventTrackerDataDto.fromJson(data)));
    sock.on(
        "updateChallengeData",
        (data) => _updateChallengeDataController
            .add(UpdateChallengeDataDto.fromJson(data)));
    _connectedController.add(null);
  }

  GameClientApi() {}
}
