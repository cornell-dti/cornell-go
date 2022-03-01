import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart';

class GameServerApi {
  final Future<bool> Function() _refreshAccess;
  final Socket _socket;

  GameServerApi(Socket socket, Future<bool> Function() refresh)
      : _refreshAccess = refresh,
        _socket = socket;

  Future<bool> _invokeWithRefresh(String ev, Map<String, dynamic> data) {
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

  Future<bool> requestRewardData(List<String> rewardIds) =>
      _invokeWithRefresh("requestRewardData", {'rewardIds': rewardIds});

  // TODO: write the rest of the API!
}
