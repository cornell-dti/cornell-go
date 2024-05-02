import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

/**
 * The user model is used to store the user data from the backend to the frontend. 
 */
class UserModel extends ChangeNotifier {
  UserDto? userData;
  Map<String, OrganizationDto> orgData = {};
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
      client.serverApi
          ?.requestOrganizationData(RequestOrganizationDataDto(admin: false));
    });

    client.clientApi.disconnectedStream.listen((event) {
      userData = null;
      orgData.clear();
    });

    client.clientApi.updateOrganizationDataStream.listen((event) {
      if (event.deleted) {
        orgData.remove(event.organization.id);
      } else {
        if (!orgData.containsKey(event.organization.id)) {
          orgData[event.organization.id] = event.organization;
        } else {
          orgData[event.organization.id]?.partialUpdate(event.organization);
        }
      }

      notifyListeners();
    });
  }

  List<String> getAvailableEventIds() {
    Set<String> evIds = Set();

    for (final org in orgData.values) {
      if (org.events != null) {
        evIds.addAll(org.events!);
      }
    }

    return evIds.toList();
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
