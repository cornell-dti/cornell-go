import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class ChallengeModel extends ChangeNotifier {
  Map<String, UpdateChallengeDataChallengeDto> _challengesById = {};
  ApiClient _client;

  ChallengeModel(ApiClient client) : _client = client {
    client.clientApi.updateChallengeDataStream.listen((event) {
      event.challenges.forEach((element) {
        _challengesById[element.id] = element;
      });
      notifyListeners();
    });

    client.clientApi.disconnectedStream.listen((event) {
      _challengesById.clear();
    });
  }

  UpdateChallengeDataChallengeDto? getChallengeById(String id) {
    final chal = _challengesById[id];
    if (chal == null) {
      _client.serverApi?.requestChallengeData([id]);
    }
    return chal;
  }
}
