import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class EventModel extends ChangeNotifier {
  Map<String, EventDto> _events = {};
  Map<String, List<UpdateLeaderDataUserDto>> _topPlayers = {};

  ApiClient _client;
  List<EventDto>? searchResults = [];

  EventModel(ApiClient client) : _client = client {
    client.clientApi.updateEventDataStream.listen((event) {
      if (!event.deleted && !event.event is String) {
        EventDto ev = event.event;
        searchResults!.add(ev);
        _events[ev.id] = ev;
        print("updated _events with " + ev.id);
      } else {
        print(event.event);
      }
      // event.event.toList().forEach((element) {
      //   _events[element.id] = element;
      // });
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

    client.clientApi.invalidateDataStream.listen((event) {
      if (event.userEventData || event.winnerRewardData) {
        _events.clear();
        searchResults = null;
      }
      if (event.leaderboardData) {
        _topPlayers.clear();
      }
      if (event.leaderboardData ||
          event.userEventData ||
          event.winnerRewardData) {
        notifyListeners();
      }
    });
  }

  List<UpdateLeaderDataUserDto> getTopPlayersForEvent(
      String eventId, int count) {
    final topPlayers = _topPlayers[eventId];
    final diff = count - (topPlayers?.length ?? 0);
    if (topPlayers == null) {
      _topPlayers[eventId] = [];
    }
    if (_topPlayers[eventId]?.length == 0) {
      eventId.isEmpty
          ? _client.serverApi
              ?.requestGlobalLeaderData((topPlayers?.length ?? 0), 1000)
          : _client.serverApi?.requestEventLeaderData(
              (topPlayers?.length ?? 0), diff, eventId);
    }
    return topPlayers ?? [];
  }

  EventDto? getEventById(String id) {
    if (_events.containsKey(id)) {
      print("getEventId got " + _events[id].toString());
      return _events[id];
    } else {
      // _client.serverApi?.requestEventData([id]);
      print("getEventId got null");
      return null;
    }
  }

  void searchEvents(int offset, int count, List<EventRewardType> rewardTypes,
      bool closestToEnding, bool shortestFirst, bool skippableOnly) {
    searchResults = null;
    _client.serverApi?.requestAllEventData(offset, count, rewardTypes,
        closestToEnding, shortestFirst, skippableOnly);
  }
}
