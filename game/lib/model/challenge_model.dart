import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class ChallengeModel extends ChangeNotifier {
  Map<String, ChallengeDto> _challengesById = {};
  ApiClient _client;

  ChallengeModel(ApiClient client) : _client = client {
    client.clientApi.updateChallengeDataStream.listen((event) {
      if (event.deleted) {
        _challengesById.remove(event.challenge.id);
      } else {
        _challengesById[event.challenge.id] = event.challenge;
      }
      notifyListeners();
    });

    client.clientApi.connectedStream.listen((event) {
      _challengesById.clear();
      notifyListeners();
    });
  }

  ChallengeDto? getChallengeById(String id) {
    final chal = _challengesById[id];
    if (chal == null) {
      _client.serverApi?.requestChallengeData([id]);
    }
    return chal;
  }
}
