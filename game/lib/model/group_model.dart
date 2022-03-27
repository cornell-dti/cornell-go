import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class GroupModel extends ChangeNotifier {
  String? curEventId;
  List<UpdateGroupDataMemberDto> members = [];

  GroupModel(ApiClient client) {
    client.clientApi.updateGroupDataStream.listen((event) {
      curEventId = event.curEventId;
      members.removeWhere(
          (element) => event.members.any((mem) => mem.id == element.id));
      if (!event.removeListedMembers) {
        members.insertAll(max(members.length - 1, 0), event.members);
      }
      members.sort((mem1, mem2) => mem1.points - mem2.points);
      notifyListeners();
    });

    client.clientApi.connectedStream.listen((event) {
      client.serverApi?.requestGroupData();
    });

    client.clientApi.disconnectedStream.listen((event) {
      members.clear();
      curEventId = null;
    });
  }
}
