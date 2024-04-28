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
      var players = _topPlayers[event.eventId];
      if (players == null) {
        players = [];
        _topPlayers[event.eventId ?? ""] = players;
      }

      for (int i = event.offset; i < event.users.length; i++) {
        if (i < players.length) {
          players[i] = event.users[i - event.offset];
        } else {
          players.add(event.users[i - event.offset]);
        }
      }

      notifyListeners();
    });

    client.clientApi.updateUserDataStream.listen((event) {
      if (event.user.username == null) return;

      for (final playerList in _topPlayers.values) {
        for (final player in playerList) {
          if (player.userId == event.user.id) {
            player.username = event.user.username!;
            break;
          }
        }
      }

      notifyListeners();
    });

    client.clientApi.updateLeaderPositionStream.listen((event) {
      final forEvent = _topPlayers[event.eventId];
      final forFull = _topPlayers[""];

      if (forEvent != null) {
        forEvent
            .firstWhere((element) => element.userId == event.playerId,
                orElse: () => LeaderDto(userId: "", username: "", score: 0))
            .score = event.newEventScore;

        forEvent.sort((a, b) => b.score.compareTo(a.score));
      }

      if (forFull != null) {
        forFull
            .firstWhere((element) => element.userId == event.playerId,
                orElse: () => LeaderDto(userId: "", username: "", score: 0))
            .score = event.newTotalScore;

        forFull.sort((a, b) => b.score.compareTo(a.score));
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

  List<LeaderDto>? getTopPlayersForEvent(String? eventId, int count) {
    final topPlayers = _topPlayers[eventId ?? ""];
    final diff = count - (topPlayers?.length ?? 0);
    if (topPlayers == null) {
      _client.serverApi?.requestEventLeaderData(RequestEventLeaderDataDto(
          offset: (topPlayers?.length ?? 0), count: diff, eventId: eventId));
    }
    return topPlayers;
  }

  EventDto? getEventById(String id) {
    if (_events.containsKey(id)) {
      return _events[id];
    } else {
      _client.serverApi?.requestEventData(RequestEventDataDto(events: [id]));
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
    _client.serverApi?.requestEventData(RequestEventDataDto());
  }
}
