import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class TrackerModel extends ChangeNotifier {
  Map<String, UpdateEventTrackerDataEventTrackerDto> _trackers = {};
  ApiClient _client;

  TrackerModel(ApiClient client) : _client = client {
    client.clientApi.updateEventTrackerDataStream.listen((event) {
      if (event.eventTrackers.length == 0) return;
      event.eventTrackers.forEach((element) {
        _trackers[element.eventId] = element;
      });
      notifyListeners();
    });

    client.clientApi.connectedStream.listen((event) {
      _trackers.clear();
      notifyListeners();
    });

    client.clientApi.invalidateDataStream.listen((event) {
      if (event.challengeData) {
        _trackers.clear();
        notifyListeners();
      }
    });
  }

  UpdateEventTrackerDataEventTrackerDto? trackerByEventId(String eventId) {
    if (_trackers.containsKey(eventId)) {
      return _trackers[eventId];
    } else {
      _client.serverApi?.requestEventTrackerData([eventId]);
      return null;
    }
  }
}
