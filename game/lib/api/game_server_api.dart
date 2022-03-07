import 'dart:async';

import 'package:game/api/game_client_dto.dart';
import 'package:socket_io_client/socket_io_client.dart';

class GameServerApi {
  final Future<bool> Function() _refreshAccess;
  Socket _socket;

  GameServerApi(Socket socket, Future<bool> Function() refresh)
      : _refreshAccess = refresh,
        _socket = socket;

  void replaceSocket(Socket socket) {
    _socket = socket;
  }

  Future<bool> _emitAck(String ev, Map<String, dynamic> data) async {
    final invoker = Completer<bool>();
    _socket.emitWithAck(ev, data, ack: (ack) {
      if (ack is bool) {
        invoker.complete(ack);
      } else {
        invoker.complete(false);
      }
    });

    return invoker.future;
  }

  Future<bool> _invokeWithRefresh(String ev, Map<String, dynamic> data) async {
    final success = await _emitAck(ev, data);
    if (!success) {
      final hasRefreshed = await _refreshAccess();

      if (hasRefreshed) {
        return await _emitAck(ev, data);
      }
      return false;
    }
    return true;
  }

  Future<bool> requestRewardData(List<String> rewardIds) =>
      _invokeWithRefresh("requestRewardData", {'rewardIds': rewardIds});

  Future<bool> requestGlobalLeaderData(int offset, int count) =>
      _invokeWithRefresh(
          "requestRewardData", {'offset': offset, 'count': count});

  Future<bool> closeAccount() => _invokeWithRefresh("closeAccount", {});
  Future<bool> setUsername(String newUsername) =>
      _invokeWithRefresh("setUsername", {'newUsername': newUsername});
  Future<bool> requestUserData() => _invokeWithRefresh("requestUserData", {});
  Future<bool> requestGroupData() => _invokeWithRefresh("requestGroupData", {});
  Future<bool> joinGroup(String groupId) =>
      _invokeWithRefresh("joinGroup", {'groupId': groupId});
  Future<bool> leaveGroup() => _invokeWithRefresh("leaveGroup", {});
  Future<bool> setCurrentEvent(String eventId) =>
      _invokeWithRefresh("setCurrentEvent", {"eventId": eventId});
  Future<bool> requestEventData(List<String> eventIds) =>
      _invokeWithRefresh("requestEventData", {"eventIds": eventIds});
  Future<bool> requestAllEventData(
          int offset,
          int count,
          List<UpdateEventDataEventRewardTypeDto> rewardTypes,
          bool closestToEnding,
          bool shortestFirst,
          bool skippableOnly) =>
      _invokeWithRefresh("requestEventData", {
        "offset": offset,
        "count": count,
        "closestToEnding": closestToEnding,
        "shortestFirst": shortestFirst,
        "skippableOnly": skippableOnly,
        "rewardTypes": rewardTypes.map((e) {
          var result = "";
          switch (e) {
            case UpdateEventDataEventRewardTypeDto.NO_REWARDS:
              result = "no_rewards";
              break;
            case UpdateEventDataEventRewardTypeDto.LIMITED_TIME_EVENT:
              result = "limited_time_event";
              break;
            case UpdateEventDataEventRewardTypeDto.RACE_TO_WIN:
              result = "race_to_win";
              break;
            case UpdateEventDataEventRewardTypeDto.WIN_ON_COMPLETION:
              result = "win_on_completion";
              break;
          }
          return result;
        })
      });

  Future<bool> requestEventLeaderData(int offset, int count, String eventId) =>
      _invokeWithRefresh("requestEventLeaderData",
          {"offset": offset, "count": count, "eventId": eventId});

  Future<bool> requestEventTrackerData(List<String> trackedEventIds) =>
      _invokeWithRefresh(
          "requestEventLeaderData", {"trackedEventIds": trackedEventIds});

  Future<bool> requestChallengeData(List<String> challengeIds) =>
      _invokeWithRefresh(
          "requestChallengeData", {"challengeIds": challengeIds});

  Future<bool> setCurrentChallenge(String challengeId) =>
      _invokeWithRefresh("setCurrentChallenge", {"challengeId": challengeId});

  Future<bool> completedChallenge(String challengeId) =>
      _invokeWithRefresh("completedChallenge", {"challengeId": challengeId});
}
