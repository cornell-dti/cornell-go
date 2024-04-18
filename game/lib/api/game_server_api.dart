// CODE AUTOGENERATED BY npm run updateapi
// IF YOU MODIFY THIS FILE, MAKE SURE TO ALSO MODIFY THE updateapi SCRIPT!
// OTHERWISE YOUR CHANGES MAY BE OVERWRITTEN!

import 'dart:async';
import 'dart:convert';
import 'package:game/api/game_client_dto.dart';
import 'package:socket_io_client/socket_io_client.dart';

class GameServerApi {
  final Future<bool> Function() _refreshAccess;
  Socket _socket;

  String _refreshEv = "";
  dynamic _refreshDat = "";

  GameServerApi(Socket socket, Future<bool> Function() refresh)
      : _refreshAccess = refresh,
        _socket = socket {
    _socket.onError((data) async {
      if (await _refreshAccess()) {
        _socket.emit(_refreshEv, _refreshDat);
      }
    });
  }

  void replaceSocket(Socket socket) {
    _socket = socket;
    _socket.onError((data) async {
      if (await _refreshAccess()) {
        _socket.emit(_refreshEv, _refreshDat);
      }
    });
  }

  void _invokeWithRefresh(String ev, Map<String, dynamic> data) {
    _refreshEv = ev;
    _refreshDat = data;
    print(ev);
    _socket.emit(ev, data);
  }

  void requestChallengeData(RequestChallengeDataDto dto) =>
      _invokeWithRefresh("requestChallengeData", dto.toJson());

  void completedChallenge(CompletedChallengeDto dto) =>
      _invokeWithRefresh("completedChallenge", dto.toJson());

  void requestGlobalLeaderData(RequestGlobalLeaderDataDto dto) =>
      _invokeWithRefresh("requestGlobalLeaderData", dto.toJson());

  void updateChallengeData(UpdateChallengeDataDto dto) =>
      _invokeWithRefresh("updateChallengeData", dto.toJson());

  void requestEventData(RequestEventDataDto dto) =>
      _invokeWithRefresh("requestEventData", dto.toJson());

  void requestRecommendedEvents(RequestRecommendedEventsDto dto) =>
      _invokeWithRefresh("requestRecommendedEvents", dto.toJson());

  void requestEventLeaderData(RequestEventLeaderDataDto dto) =>
      _invokeWithRefresh("requestEventLeaderData", dto.toJson());

  void requestEventTrackerData(RequestEventTrackerDataDto dto) =>
      _invokeWithRefresh("requestEventTrackerData", dto.toJson());

  void updateEventData(UpdateEventDataDto dto) =>
      _invokeWithRefresh("updateEventData", dto.toJson());

  void requestGroupData(RequestGroupDataDto dto) =>
      _invokeWithRefresh("requestGroupData", dto.toJson());

  void joinGroup(JoinGroupDto dto) =>
      _invokeWithRefresh("joinGroup", dto.toJson());

  void leaveGroup(LeaveGroupDto dto) =>
      _invokeWithRefresh("leaveGroup", dto.toJson());

  void setCurrentEvent(SetCurrentEventDto dto) =>
      _invokeWithRefresh("setCurrentEvent", dto.toJson());

  void updateGroupData(UpdateGroupDataDto dto) =>
      _invokeWithRefresh("updateGroupData", dto.toJson());

  void sendGroupInvite(SendGroupInviteDto dto) =>
      _invokeWithRefresh("sendGroupInvite", dto.toJson());

  void requestOrganizationData(RequestOrganizationDataDto dto) =>
      _invokeWithRefresh("requestOrganizationData", dto.toJson());

  void updateOrganizationData(UpdateOrganizationDataDto dto) =>
      _invokeWithRefresh("updateOrganizationData", dto.toJson());

  void requestAllUserData(RequestAllUserDataDto dto) =>
      _invokeWithRefresh("requestAllUserData", dto.toJson());

  void requestUserData(RequestUserDataDto dto) =>
      _invokeWithRefresh("requestUserData", dto.toJson());

  void updateUserData(UpdateUserDataDto dto) =>
      _invokeWithRefresh("updateUserData", dto.toJson());

  void setAuthToDevice(SetAuthToDeviceDto dto) =>
      _invokeWithRefresh("setAuthToDevice", dto.toJson());

  void setAuthToOAuth(SetAuthToOAuthDto dto) =>
      _invokeWithRefresh("setAuthToOAuth", dto.toJson());

  void banUser(BanUserDto dto) => _invokeWithRefresh("banUser", dto.toJson());

  void addManager(AddManagerDto dto) =>
      _invokeWithRefresh("addManager", dto.toJson());

  void joinOrganization(JoinOrganizationDto dto) =>
      _invokeWithRefresh("joinOrganization", dto.toJson());

  void closeAccount(CloseAccountDto dto) =>
      _invokeWithRefresh("closeAccount", dto.toJson());
}
