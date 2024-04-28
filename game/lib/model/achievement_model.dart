import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

/**
 * This file represents the model for the achievements. Whenever a achievement is updated, added or deleted from the backend, the model is updated and notifies the Consumer so that the front end can be modified. 
 */
class AchievementModel extends ChangeNotifier {
  Map<String, AchievementDto> _achievementsById = {};
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
      notifyListeners();
    });
  }
}
