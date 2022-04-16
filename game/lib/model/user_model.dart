import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class UserModel extends ChangeNotifier {
  UpdateUserDataDto? userData;

  UserModel(ApiClient client) {
    client.clientApi.updateUserDataStream.listen((event) {
      if (userData == null) userData = event;
      if (event.ignoreIdLists) {
        userData?.groupId = event.groupId;
        userData?.authType = event.authType;
        userData?.score = event.score;
        userData?.username = event.username;
      } else {
        userData = event;
      }
      notifyListeners();
    });

    client.clientApi.connectedStream.listen((event) {
      userData = null;
      client.serverApi?.requestUserData();
    });

    client.clientApi.invalidateDataStream.listen((event) {
      client.serverApi?.requestUserData();
    });
  }
}
