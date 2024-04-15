import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

/**
 * The user model is used to store the user data from the backend to the frontend. 
 */
class UserModel extends ChangeNotifier {
  UserDto? userData;

  UserModel(ApiClient client) {
    /**
     * Stream that listens to updates on the user data.
     */
    client.clientApi.updateUserDataStream.listen((event) {
      if (userData == null) userData = event.user;

      userData?.partialUpdate(event.user);
      notifyListeners();
    });

    client.clientApi.connectedStream.listen((event) {
      userData = null;
      client.serverApi?.requestUserData(RequestUserDataDto());
    });
  }
}
