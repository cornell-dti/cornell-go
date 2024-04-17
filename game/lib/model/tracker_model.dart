import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

/**
 * The tracker model is used to store the tracker data from the backend to the frontend. 
 */
class TrackerModel extends ChangeNotifier {
  Map<String, EventTrackerDto> _trackers = {};
  ApiClient _client;

  TrackerModel(ApiClient client) : _client = client {
    /**
     * Stream that listens to updates on the tracker data.
     */
    client.clientApi.updateEventTrackerDataStream.listen((event) {
      _trackers[event.eventId] = event;

      notifyListeners();
    });

    client.clientApi.connectedStream.listen((event) {
      _trackers.clear();
      notifyListeners();
    });
  }

  /**
   * Returns the tracker data for the given event id.
   * 
   * If the tracker data is not available, it will request the data from the server, which then will be updated in the model throught the listening stream
   */
  EventTrackerDto? trackerByEventId(String eventId) {
    if (_trackers.containsKey(eventId)) {
      return _trackers[eventId];
    } else {
      _client.serverApi?.requestEventTrackerData(
          RequestEventTrackerDataDto(trackedEvents: [eventId]));
      return null;
    }
  }

  /** 
   * Use a hint for the tracker associated with the given event id.
   */
  void useEventTrackerHint(String eventId) {
    if (_trackers.containsKey(eventId)) {
      _client.serverApi
          ?.useEventTrackerHint(UseEventTrackerHintDto(usedHint: true));
    } else {
      return null;
    }
  }
}
