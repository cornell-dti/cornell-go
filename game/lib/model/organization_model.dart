import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:velocity_x/velocity_x.dart';

class OrganizationModel extends ChangeNotifier {
  ApiClient _client;
  Map<String, OrganizationDto> _organizationsById = {};

  OrganizationModel(ApiClient client) : _client = client {
    client.clientApi.updateOrganizationDataStream.listen((event) {
      if (event.deleted) {
        _organizationsById.removeWhere((id, org) => event.organizationId == id);
      } else {
        _organizationsById[event.organizationId] = event.organization!;
      }
      notifyListeners();
    });

    client.clientApi.connectedStream.listen((event) {
      _organizationsById.clear();
      notifyListeners();
    });

    client.clientApi.invalidateDataStream.listen((event) {
      if (event.challengeData) {
        _organizationsById.clear();
        notifyListeners();
      }
    });
  }

  // Get single organization by id
  OrganizationDto? getOrganizationById(String id) {
    if (_organizationsById.containsKey(id)) {
      return _organizationsById[id];
    }
    return null;
  }

  // Get all the user's organizations as ids
  List<String> getOrganizationIds() {
    return _organizationsById.keysList();
  }

  // Get all allowed event ids
  List<String> getAllowedEventIds() {
    Set<String> eventIds = Set();
    for (String id in _organizationsById.keys) {
      eventIds.union(_organizationsById[id]!.events.toSet());
    }
    return eventIds.toList();
  }
}
