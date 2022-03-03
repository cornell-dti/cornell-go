import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class ChallengeModel extends ChangeNotifier {
  Map<String, UpdateChallengeDataChallengeDto> _challengesById = {};

  ChallengeModel(ApiClient client) {
    client.clientApi.updateChallengeDataStream.listen((event) {
      event.challenges.forEach((element) {
        _challengesById[element.id] = element;
      });
      notifyListeners();
    });
  }
}
