// CODE AUTOGENERATED BY npm run updateapi
// IF YOU MODIFY THIS FILE, MAKE SURE TO ALSO MODIFY THE updateapi SCRIPT!
// OTHERWISE YOUR CHANGES MAY BE OVERWRITTEN!

import 'dart:async';

import 'package:game/api/game_client_dto.dart';
import 'package:socket_io_client/socket_io_client.dart';

class GameClientApi {
  final _updateUserDataController =
      StreamController<UpdateUserDataDto>.broadcast(sync: true);
  Stream<UpdateUserDataDto> get updateUserDataStream =>
      _updateUserDataController.stream;

  final _updateErrorDataController =
      StreamController<UpdateErrorDto>.broadcast(sync: true);
  Stream<UpdateErrorDto> get updateErrorDataStream =>
      _updateErrorDataController.stream;

  final _updateChallengeDataController =
      StreamController<UpdateChallengeDataDto>.broadcast(sync: true);
  Stream<UpdateChallengeDataDto> get updateChallengeDataStream =>
      _updateChallengeDataController.stream;

  final _updateAchievementDataController =
      StreamController<UpdateAchievementDataDto>.broadcast(sync: true);
  Stream<UpdateAchievementDataDto> get updateAchievementDataStream =>
      _updateAchievementDataController.stream;

  final _updateAchievementTrackerDataController =
      StreamController<AchievementTrackerDto>.broadcast(sync: true);
  Stream<AchievementTrackerDto> get updateAchievementTrackerDataStream =>
      _updateAchievementTrackerDataController.stream;

  final _updateEventTrackerDataController =
      StreamController<EventTrackerDto>.broadcast(sync: true);
  Stream<EventTrackerDto> get updateEventTrackerDataStream =>
      _updateEventTrackerDataController.stream;

  final _updateEventDataController =
      StreamController<UpdateEventDataDto>.broadcast(sync: true);
  Stream<UpdateEventDataDto> get updateEventDataStream =>
      _updateEventDataController.stream;

  final _updateLeaderDataController =
      StreamController<UpdateLeaderDataDto>.broadcast(sync: true);
  Stream<UpdateLeaderDataDto> get updateLeaderDataStream =>
      _updateLeaderDataController.stream;

  final _groupInvitationController =
      StreamController<GroupInviteDto>.broadcast(sync: true);
  Stream<GroupInviteDto> get groupInvitationStream =>
      _groupInvitationController.stream;

  final _updateGroupDataController =
      StreamController<UpdateGroupDataDto>.broadcast(sync: true);
  Stream<UpdateGroupDataDto> get updateGroupDataStream =>
      _updateGroupDataController.stream;

  final _updateOrganizationDataController =
      StreamController<UpdateOrganizationDataDto>.broadcast(sync: true);
  Stream<UpdateOrganizationDataDto> get updateOrganizationDataStream =>
      _updateOrganizationDataController.stream;

  final _updateLeaderPositionController =
      StreamController<UpdateLeaderPositionDto>.broadcast(sync: true);
  Stream<UpdateLeaderPositionDto> get updateLeaderPositionStream =>
      _updateLeaderPositionController.stream;

  final _reconnectedController = StreamController<bool>.broadcast(sync: true);
  Stream<bool> get reconnectedStream => _reconnectedController.stream;

  final _reconnectingController = StreamController<bool>.broadcast(sync: true);
  Stream<bool> get reconnectingStream => _reconnectingController.stream;

  final _connectedController = StreamController<bool>.broadcast(sync: true);
  Stream<bool> get connectedStream => _connectedController.stream;

  final disconnectedController = StreamController<bool>.broadcast(sync: true);
  Stream<bool> get disconnectedStream => disconnectedController.stream;

  void connectSocket(Socket sock) {
    sock.onReconnect((data) => _reconnectedController.add(true));
    sock.onReconnecting((data) => _reconnectingController.add(true));
    sock.onDisconnect((data) => disconnectedController.add(true));

    sock.on(
        "updateUserData",
        (data) =>
            _updateUserDataController.add(UpdateUserDataDto.fromJson(data)));

    sock.on(
        "updateErrorData",
        (data) =>
            _updateErrorDataController.add(UpdateErrorDto.fromJson(data)));

    sock.on(
        "updateChallengeData",
        (data) => _updateChallengeDataController
            .add(UpdateChallengeDataDto.fromJson(data)));

    sock.on(
        "updateAchievementData",
        (data) => _updateAchievementDataController
            .add(UpdateAchievementDataDto.fromJson(data)));

    sock.on(
        "updateAchievementTrackerData",
        (data) => _updateAchievementTrackerDataController
            .add(AchievementTrackerDto.fromJson(data)));

    sock.on(
        "updateEventTrackerData",
        (data) => _updateEventTrackerDataController
            .add(EventTrackerDto.fromJson(data)));

    sock.on(
        "updateEventData",
        (data) =>
            _updateEventDataController.add(UpdateEventDataDto.fromJson(data)));

    sock.on(
        "updateLeaderData",
        (data) => _updateLeaderDataController
            .add(UpdateLeaderDataDto.fromJson(data)));

    sock.on(
        "groupInvitation",
        (data) =>
            _groupInvitationController.add(GroupInviteDto.fromJson(data)));

    sock.on(
        "updateGroupData",
        (data) =>
            _updateGroupDataController.add(UpdateGroupDataDto.fromJson(data)));

    sock.on(
        "updateOrganizationData",
        (data) => _updateOrganizationDataController
            .add(UpdateOrganizationDataDto.fromJson(data)));

    sock.on(
        "updateLeaderPosition",
        (data) => _updateLeaderPositionController
            .add(UpdateLeaderPositionDto.fromJson(data)));

    _connectedController.add(true);
  }

  GameClientApi() {}
}
