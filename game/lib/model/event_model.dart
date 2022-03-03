import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class EventModel extends ChangeNotifier {
  Map<String, UpdateEventDataEventDto> _events = {};
  ApiClient _client;
  List<UpdateEventDataEventDto>? searchResults;

  EventModel(ApiClient client) : _client = client {
    client.clientApi.updateEventDataStream.listen((event) {
      if (event.isSearch) {
        searchResults = event.events;
      }
      event.events.forEach((element) {
        _events[element.id] = element;
      });
      notifyListeners();
    });
  }

  UpdateEventDataEventDto? getEventById(String id) {
    if (_events.containsKey(id)) {
      return _events[id];
    } else {
      _client.serverApi?.requestEventData([id]);
      return null;
    }
  }

  void searchEvents(
      int offset,
      int count,
      List<UpdateEventDataEventRewardTypeDto> rewardTypes,
      bool closestToEnding,
      bool shortestFirst,
      bool skippableOnly) {
    searchResults = null;
    _client.serverApi?.requestAllEventData(offset, count, rewardTypes,
        closestToEnding, shortestFirst, skippableOnly);
  }
}
