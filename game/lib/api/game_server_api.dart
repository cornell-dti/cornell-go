// CODE AUTOGENERATED BY npm run updateapi
// IF YOU MODIFY THIS FILE, MAKE SURE TO ALSO MODIFY THE updateapi SCRIPT!
// OTHERWISE YOUR CHANGES MAY BE OVERWRITTEN!

import 'dart:async';
import 'dart:convert';
import 'package:game/api/game_client_dto.dart';
import 'package:socket_io_client/socket_io_client.dart';

class GameServerApi {
  final Future<bool> Function() _refreshAccess;

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

    final completionFunc = (arg) {
      if (completer.isCompleted) {
        return;
      }

      completer.complete(arg);
    };

    Future.delayed(Duration(seconds: 2))
        .then((value) => completer.complete(null));

    _refreshEv = ev;
    _refreshDat = data;
    _refreshResolver = completionFunc;

    print(ev);
    _socket.emitWithAck(ev, data, ack: completionFunc);

    return completer.future;
  }

  Future<int?> requestAchievementData(RequestAchievementDataDto dto) =>
      _invokeWithRefresh("requestAchievementData", dto.toJson());

  Future<String?> updateAchievementData(UpdateAchievementDataDto dto) =>
      _invokeWithRefresh("updateAchievementData", dto.toJson());

  Future<int?> requestChallengeData(RequestChallengeDataDto dto) =>
      _invokeWithRefresh("requestChallengeData", dto.toJson());

  Future<String?> updateChallengeData(UpdateChallengeDataDto dto) =>
      _invokeWithRefresh("updateChallengeData", dto.toJson());

  Future<int?> requestEventData(RequestEventDataDto dto) =>
      _invokeWithRefresh("requestEventData", dto.toJson());

  Future<int?> requestFilteredEventIds(RequestFilteredEventsDto dto) =>
      _invokeWithRefresh("requestFilteredEventIds", dto.toJson());

  Future<int?> requestRecommendedEvents(RequestRecommendedEventsDto dto) =>
      _invokeWithRefresh("requestRecommendedEvents", dto.toJson());

  Future<int?> requestEventLeaderData(RequestEventLeaderDataDto dto) =>
      _invokeWithRefresh("requestEventLeaderData", dto.toJson());

  Future<int?> requestEventTrackerData(RequestEventTrackerDataDto dto) =>
      _invokeWithRefresh("requestEventTrackerData", dto.toJson());

  Future<String?> updateEventData(UpdateEventDataDto dto) =>
      _invokeWithRefresh("updateEventData", dto.toJson());

  Future<int?> requestOrganizationData(RequestOrganizationDataDto dto) =>
      _invokeWithRefresh("requestOrganizationData", dto.toJson());

  Future<String?> updateOrganizationData(UpdateOrganizationDataDto dto) =>
      _invokeWithRefresh("updateOrganizationData", dto.toJson());

  Future<int?> requestAllUserData(RequestAllUserDataDto dto) =>
      _invokeWithRefresh("requestAllUserData", dto.toJson());

  Future<String?> addManager(AddManagerDto dto) async =>
      await _invokeWithRefresh("addManager", dto.toJson());
}
