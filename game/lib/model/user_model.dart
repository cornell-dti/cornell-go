import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

/**
 * The user model is used to store the user data from the backend to the frontend. 
 */
class UserModel extends ChangeNotifier {
  UserDto? userData;
  ApiClient _client;

  UserModel(ApiClient client) : _client = client {
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

  void updateUserData(String id, String? username, String? college,
      String? major, String? year) {
    _client.serverApi?.updateUserData(UpdateUserDataDto(
        user: UserDto(
            id: id,
            username: username,
            college: college,
            major: major,
            year: year),
        deleted: false));
  }
}
