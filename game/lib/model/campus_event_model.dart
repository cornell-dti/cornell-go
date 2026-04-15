import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class CampusEventModel extends ChangeNotifier {
  final Map<String, CampusEventDto> _eventsById = {};
  CampusEventListDto? _currentList;
  final ApiClient _client;

  CampusEventModel(ApiClient client) : _client = client {
    client.clientApi.updateCampusEventDataStream.listen((event) {
      if (event.deleted) {
        _eventsById.remove(event.event.id);
      } else {
        _eventsById[event.event.id] = event.event;
      }
      notifyListeners();
    });

    client.clientApi.campusEventListStream.listen((event) {
      _currentList = event.list;
      for (final campusEvent in event.list.events) {
        _eventsById[campusEvent.id] = campusEvent;
      }
      notifyListeners();
    });

    client.clientApi.connectedStream.listen((event) {
      _eventsById.clear();
      _currentList = null;
      notifyListeners();
    });
  }

  CampusEventDto? getCampusEventById(String id) {
    final event = _eventsById[id];
    if (event == null) {
      _client.serverApi?.requestCampusEventDetails(
        RequestCampusEventDetailsDto(eventId: id),
      );
    }
    return event;
  }

  CampusEventListDto? get currentList => _currentList;

  List<CampusEventDto> get allCachedEvents => _eventsById.values.toList();

  void requestCampusEvents({
    int page = 1,
    int limit = 20,
    String? dateFrom,
    String? dateTo,
    List<RequestCampusEventsCategoriesDto>? categories,
    String? search,
    bool? featured,
  }) {
    _client.serverApi?.requestCampusEvents(
      RequestCampusEventsDto(
        page: page,
        limit: limit,
        dateFrom: dateFrom,
        dateTo: dateTo,
        categories: categories,
        search: search,
        featured: featured,
      ),
    );
  }

  void rsvpCampusEvent(String campusEventId) {
    _client.serverApi?.rsvpCampusEvent(
      RsvpCampusEventDto(eventId: campusEventId),
    );
  }

  void unRsvpCampusEvent(String campusEventId) {
    _client.serverApi?.unRsvpCampusEvent(
      UnRsvpCampusEventDto(eventId: campusEventId),
    );
  }
}
