import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class EventModel extends ChangeNotifier {
  Map<String, UpdateEventDataEventDto> _events = {};
  Map<String, int> _topPlayerLength = {};
  Map<String, List<UpdateLeaderDataUserDto>> _topPlayers = {};

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

    client.clientApi.updateLeaderDataStream.listen((event) {
      final players = _topPlayers[event.eventId];
      for (int i = event.offset; i < event.users.length; i++) {
        if (i > _topPlayers.length) {
          players?.add(event.users[i - event.users.length]);
        } else {
          players?[i] = event.users[i - event.users.length];
        }
      }
      int diff = _topPlayerLength.length - (players?.length ?? 0);
      if (diff > 0) {
        client.serverApi
            ?.requestEventLeaderData(players?.length ?? 0, diff, event.eventId);
      }
      notifyListeners();
    });
  }

  List<UpdateLeaderDataUserDto> getTopPlayersForEvent(
      String eventId, int count) {
    final topPlayers = _topPlayers[eventId];
    if (topPlayers != null) {
      final toLoad = _topPlayerLength[eventId]!;
      if (count > toLoad) {
        _topPlayerLength[eventId] = count;
        _client.serverApi
            ?.requestEventLeaderData(toLoad, toLoad - count, eventId);
      }
      return topPlayers;
    } else {
      _topPlayers[eventId] = [];
      _topPlayerLength[eventId] = 0;
      _client.serverApi?.requestEventLeaderData(0, count, eventId);
      return [];
    }
  }

  bool isLoadingPlayers(String eventId) {
    if (_topPlayers.containsKey(eventId)) {
      return _topPlayers[eventId]?.length != _topPlayerLength[eventId];
    } else {
      return true;
    }
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
