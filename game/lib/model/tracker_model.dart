import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class TrackerModel extends ChangeNotifier {
  Map<String, EventTrackerDto> _trackers = {};
  ApiClient _client;

  TrackerModel(ApiClient client) : _client = client {
    client.clientApi.updateEventTrackerDataStream.listen((event) {
      if (event.tracker == null) return;
      _trackers[event.tracker!.eventId] = event.tracker!;

      notifyListeners();
    });

    client.clientApi.connectedStream.listen((event) {
      _trackers.clear();
      notifyListeners();
    });
  }

  EventTrackerDto? trackerByEventId(String eventId) {
    if (_trackers.containsKey(eventId)) {
      return _trackers[eventId];
    } else {
      _client.serverApi?.requestEventTrackerData([eventId]);
      return null;
    }
  }
}
