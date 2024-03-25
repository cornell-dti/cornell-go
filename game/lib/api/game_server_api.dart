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

  void requestGlobalLeaderData(int offset, int count) => _invokeWithRefresh(
      "requestGlobalLeaderData", {'offset': offset, 'count': count});

  void closeAccount() => _invokeWithRefresh("closeAccount", {});
  void updateUserData(UserDto dto) =>
      _invokeWithRefresh("updateUserData", {"user": dto, "deleted": "false"});
  void requestUserData() => _invokeWithRefresh("requestUserData", {});
  void requestGroupData() => _invokeWithRefresh("requestGroupData", {});
  void joinGroup(String groupId) =>
      _invokeWithRefresh("joinGroup", {'groupId': groupId});
  void leaveGroup() => _invokeWithRefresh("leaveGroup", {});
  void setCurrentEvent(String eventId) =>
      _invokeWithRefresh("setCurrentEvent", {"eventId": eventId});
  void requestEventData(List<String> events) =>
      _invokeWithRefresh("requestEventData", {"events": events});
  void requestAllEventData(
          int offset,
          int count,
          List<EventTimeLimitationDto> timeLimitations,
          bool closestToEnding,
          bool shortestFirst,
          bool skippableOnly) =>
      _invokeWithRefresh("requestAllEventData", {
        "offset": offset,
        "count": count,
        "closestToEnding": closestToEnding,
        "shortestFirst": shortestFirst,
        "skippableOnly": skippableOnly,
        "timeLimitations": timeLimitations.map((e) => e.toString()).toList()
      });

  void requestEventLeaderData(int offset, int count, String eventId) =>
      _invokeWithRefresh("requestEventLeaderData",
          {"offset": offset, "count": count, "eventId": eventId});

  void requestEventTrackerData(List<String> trackedEvents) =>
      _invokeWithRefresh(
          "requestEventTrackerData", {"trackedEvents": trackedEvents});

  void requestChallengeData(List<String> challenges) =>
      _invokeWithRefresh("requestChallengeData", {"challenges": challenges});

  void setCurrentChallenge(String challengeId) =>
      _invokeWithRefresh("setCurrentChallenge", {"challengeId": challengeId});

  void completedChallenge(String challengeId) =>
      _invokeWithRefresh("completedChallenge", {"challengeId": challengeId});

  void requestOrganizationData() =>
      _invokeWithRefresh("requestOrganizationData", {});
}
