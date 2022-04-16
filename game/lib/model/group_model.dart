import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class GroupModel extends ChangeNotifier {
  String? curEventId;
  List<UpdateGroupDataMemberDto> members = [];

  GroupModel(ApiClient client) {
    client.clientApi.updateGroupDataStream.listen((event) {
      client.serverApi?.setCurrentEvent(event.curEventId);
      curEventId = event.curEventId;
      members.removeWhere(
          (element) => event.members.any((mem) => mem.id == element.id));
      members.clear();
      if (!event.removeListedMembers) {
        members.insertAll(max(members.length - 1, 0), event.members);
      }
      members.sort((mem1, mem2) => mem1.points - mem2.points);
      notifyListeners();
    });

    client.clientApi.connectedStream.listen((event) {
      members.clear();
      curEventId = null;
      client.serverApi?.requestGroupData();
    });

    client.clientApi.invalidateDataStream.listen((event) {
      if (event.groupData) {
        members.clear();
        curEventId = null;
        client.serverApi?.requestGroupData();
      }
    });
  }
}
