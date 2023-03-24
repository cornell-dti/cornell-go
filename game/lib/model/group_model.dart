import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class GroupModel extends ChangeNotifier {
  String? curEventId;
  List<GroupMemberDto> members = [];

  GroupDto? group = null;

  GroupModel(ApiClient client) {
    client.clientApi.updateGroupDataStream.listen((event) {
      print(event);
      if (!(event.group is String)) {
        group = event.group!;
        client.serverApi?.setCurrentEvent(event.group!.curEventId);
        curEventId = event.group!.curEventId;
        members.removeWhere((element) =>
            event.group!.members.any((mem) => mem.id == element.id));
        members.clear();
        members.sort((mem1, mem2) => mem1.points - mem2.points);
        notifyListeners();
      }
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
