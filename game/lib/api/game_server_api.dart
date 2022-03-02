import 'dart:async';

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

  // TODO: write the rest of the API!
}
