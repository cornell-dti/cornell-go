import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class EventModel extends ChangeNotifier {
  Map<String, EventDto> _events = {};
  Map<String, List<LeaderDto>> _topPlayers = {};

  ApiClient _client;
  List<EventDto>? searchResults;

  EventModel(ApiClient client) : _client = client {
    client.clientApi.updateEventDataStream.listen((event) {
      if (!event.deleted) {
        //initialize searchResults if null
        searchResults = searchResults ?? [];
        //add or update event
        if (!_events.containsKey(event.event.id)) {
          searchResults!.add(event.event);
        } else {
          var index = searchResults!
              .indexWhere((element) => element.id == event.event.id);
          searchResults![index] = event.event;
        }
        _events[event.event.id] = event.event;
      } else {
        //delete event
        _events.remove(event.event);
        searchResults?.removeWhere((element) => element.id == event.event);
      }

      notifyListeners();
    });

    client.clientApi.updateLeaderDataStream.listen((event) {
      if (event.users.length == 0) {
        return;
      }
      final players = _topPlayers[event.eventId];
      for (int i = event.offset; i < event.users.length; i++) {
        if (i < players!.length) {
          players[i] = event.users[i - event.offset];
        } else {
          players.add(event.users[i - event.offset]);
        }
      }
      notifyListeners();
    });

    client.clientApi.connectedStream.listen((event) {
      _events.clear();
      _topPlayers.clear();
      searchResults = null;
      notifyListeners();
    });
  }

  List<LeaderDto> getTopPlayersForEvent(String eventId, int count) {
    final topPlayers = _topPlayers[eventId];
    final diff = count - (topPlayers?.length ?? 0);
    if (topPlayers == null) {
      _topPlayers[eventId] = [];
    }
    if (_topPlayers[eventId]?.length == 0) {
      eventId.isEmpty
          ? _client.serverApi?.requestGlobalLeaderData(
              RequestGlobalLeaderDataDto((topPlayers?.length ?? 0), 1000))
          : _client.serverApi?.requestEventLeaderData(RequestEventLeaderDataDto(
              (topPlayers?.length ?? 0), diff, eventId));
    }
    return topPlayers ?? [];
  }

  EventDto? getEventById(String id) {
    if (_events.containsKey(id)) {
      return _events[id];
    } else {
      _client.serverApi?.requestEventData(RequestEventDataDto([id]));
      return null;
    }
  }

  void searchEvents(
      int offset,
      int count,
      List<EventTimeLimitationDto> timeLimitations,
      bool closestToEnding,
      bool shortestFirst,
      bool skippableOnly) {
    searchResults = null;
    _client.serverApi?.requestEventData(RequestEventDataDto(null));
  }
}
