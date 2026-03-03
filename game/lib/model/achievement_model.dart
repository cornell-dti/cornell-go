import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:velocity_x/velocity_x.dart';

/**
 * This file represents the model for the achievements. Whenever a achievement is updated, added or deleted from the backend, the model is updated and notifies the Consumer so that the front end can be modified. 
 */
class AchievementModel extends ChangeNotifier {
  Map<String, AchievementDto> _achievementsById = {};
  Map<String, AchievementTrackerDto> _trackersByAchId = {};
  ApiClient _client;

  AchievementModel(ApiClient client) : _client = client {
    /**
     * Stream that listens to updates on the achievements.
     */
    client.clientApi.updateAchievementDataStream.listen((event) {
      if (event.deleted) {
        _achievementsById.remove(event.achievement.id);
      } else {
        _achievementsById[event.achievement.id] = event.achievement;
      }
      notifyListeners();
    });

    client.clientApi.connectedStream.listen((event) {
      _achievementsById.clear();

      client.serverApi?.requestAchievementData(
        RequestAchievementDataDto(achievements: []),
      );
      client.serverApi?.requestAchievementTrackerData(
        RequestAchievementTrackerDataDto(),
      );

      notifyListeners();
    });

    client.clientApi.updateAchievementTrackerDataStream.listen((event) {
      _trackersByAchId[event.achievementId] = event;
      notifyListeners();
    });
  }

  AchievementDto? getAchievementById(String id) {
    if (_achievementsById.containsKey(id)) {
      return _achievementsById[id];
    } else {
      _client.serverApi?.requestAchievementData(
        RequestAchievementDataDto(achievements: [id]),
      );
      return null;
    }
  }

  List<AchievementTrackerDto> getAchievementTrackers() {
    return _trackersByAchId.valuesList();
  }

  List<(AchievementTrackerDto, AchievementDto)> getAvailableTrackerPairs({
    required List<String> allowedAchievementIds,
  }) {
    final achTrackers = getAchievementTrackers();

    // Filters achievements by organizing membership before returning tracker pairs
    return achTrackers
        .where((t) => allowedAchievementIds.contains(t.achievementId))
        .map((t) => (t, getAchievementById(t.achievementId)))
        .where((pair) => pair.$2 != null)
        .map((pair) => (pair.$1, pair.$2!))
        .toList();
  }
}
