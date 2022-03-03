import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class UserModel extends ChangeNotifier {
  UpdateUserDataDto? userData;

  UserModel(ApiClient client) {
    client.clientApi.updateUserDataStream.listen((event) {
      notifyListeners();
    })
  }
}