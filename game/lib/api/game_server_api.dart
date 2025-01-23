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
  dynamic _refreshResolver = (arg) {};

  GameServerApi(Socket socket, Future<bool> Function() refresh)
      : _refreshAccess = refresh,
        _socket = socket {
    _socket.onError((data) async {
      if (await _refreshAccess()) {
        _socket.emitWithAck(_refreshEv, _refreshDat, ack: _refreshResolver);
      }
    });
  }

  void replaceSocket(Socket socket) {
    _socket = socket;
    _socket.onError((data) async {
      if (await _refreshAccess()) {
        _socket.emitWithAck(_refreshEv, _refreshDat, ack: _refreshResolver);
      }
    });
  }

  Future<dynamic> _invokeWithRefresh(String ev, Map<String, dynamic> data) {
    Completer<dynamic> completer = Completer();
    bool isCompleted = false;

    final completionFunc = (arg) {
      if (!isCompleted) {
        isCompleted = true;
        completer.complete(arg);
      }
    };

    Future.delayed(Duration(seconds: 5)).then((_) {
      if (!isCompleted) {
        isCompleted = true;
        completer.completeError(TimeoutException('Operation timed out'));
      }
    });

    _refreshEv = ev;
    _refreshDat = data;
    _refreshResolver = completionFunc;

    print(ev);
    _socket.emitWithAck(ev, data, ack: completionFunc);

    return completer.future;
  }

  Future<int?> requestAchievementData(RequestAchievementDataDto dto) async =>
      await _invokeWithRefresh("requestAchievementData", dto.toJson());

  Future<int?> requestAchievementTrackerData(
          RequestAchievementTrackerDataDto dto) async =>
      await _invokeWithRefresh("requestAchievementTrackerData", dto.toJson());

  Future<String?> updateAchievementData(UpdateAchievementDataDto dto) async =>
      await _invokeWithRefresh("updateAchievementData", dto.toJson());

  Future<int?> requestChallengeData(RequestChallengeDataDto dto) async =>
      await _invokeWithRefresh("requestChallengeData", dto.toJson());

  Future<String?> completedChallenge(CompletedChallengeDto dto) async =>
      await _invokeWithRefresh("completedChallenge", dto.toJson());

  Future<String?> updateChallengeData(UpdateChallengeDataDto dto) async =>
      await _invokeWithRefresh("updateChallengeData", dto.toJson());

  Future<int?> requestEventData(RequestEventDataDto dto) async =>
      await _invokeWithRefresh("requestEventData", dto.toJson());

  Future<int?> requestFilteredEventIds(RequestFilteredEventsDto dto) async =>
      await _invokeWithRefresh("requestFilteredEventIds", dto.toJson());

  Future<int?> requestRecommendedEvents(
          RequestRecommendedEventsDto dto) async =>
      await _invokeWithRefresh("requestRecommendedEvents", dto.toJson());

  Future<int?> requestEventLeaderData(RequestEventLeaderDataDto dto) async =>
      await _invokeWithRefresh("requestEventLeaderData", dto.toJson());

  Future<int?> requestEventTrackerData(RequestEventTrackerDataDto dto) async =>
      await _invokeWithRefresh("requestEventTrackerData", dto.toJson());

  Future<bool?> useEventTrackerHint(UseEventTrackerHintDto dto) async =>
      await _invokeWithRefresh("useEventTrackerHint", dto.toJson());

  Future<String?> updateEventData(UpdateEventDataDto dto) async =>
      await _invokeWithRefresh("updateEventData", dto.toJson());

  Future<bool?> requestGroupData(RequestGroupDataDto dto) async =>
      await _invokeWithRefresh("requestGroupData", dto.toJson());

  Future<bool?> joinGroup(JoinGroupDto dto) async =>
      await _invokeWithRefresh("joinGroup", dto.toJson());

  Future<bool?> leaveGroup(LeaveGroupDto dto) async =>
      await _invokeWithRefresh("leaveGroup", dto.toJson());

  Future<bool?> setCurrentEvent(SetCurrentEventDto dto) async =>
      await _invokeWithRefresh("setCurrentEvent", dto.toJson());

  Future<bool?> updateGroupData(UpdateGroupDataDto dto) async =>
      await _invokeWithRefresh("updateGroupData", dto.toJson());

  Future<bool?> sendGroupInvite(SendGroupInviteDto dto) async =>
      await _invokeWithRefresh("sendGroupInvite", dto.toJson());

  Future<int?> requestOrganizationData(RequestOrganizationDataDto dto) async =>
      await _invokeWithRefresh("requestOrganizationData", dto.toJson());

  Future<String?> updateOrganizationData(UpdateOrganizationDataDto dto) async =>
      await _invokeWithRefresh("updateOrganizationData", dto.toJson());

  Future<int?> requestAllUserData(RequestAllUserDataDto dto) async =>
      await _invokeWithRefresh("requestAllUserData", dto.toJson());

  Future<bool?> requestUserData(RequestUserDataDto dto) async =>
      await _invokeWithRefresh("requestUserData", dto.toJson());

  Future<bool?> updateUserData(UpdateUserDataDto dto) async =>
      await _invokeWithRefresh("updateUserData", dto.toJson());

  Future<bool?> setAuthToDevice(SetAuthToDeviceDto dto) async =>
      await _invokeWithRefresh("setAuthToDevice", dto.toJson());

  Future<bool?> setAuthToOAuth(SetAuthToOAuthDto dto) async =>
      await _invokeWithRefresh("setAuthToOAuth", dto.toJson());

  Future<bool?> banUser(BanUserDto dto) async =>
      await _invokeWithRefresh("banUser", dto.toJson());

  Future<String?> addManager(AddManagerDto dto) async =>
      await _invokeWithRefresh("addManager", dto.toJson());

  Future<bool?> joinOrganization(JoinOrganizationDto dto) async =>
      await _invokeWithRefresh("joinOrganization", dto.toJson());

  Future<bool?> closeAccount(CloseAccountDto dto) async =>
      await _invokeWithRefresh("closeAccount", dto.toJson());
}
