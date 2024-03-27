import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

/**
 * This file represents the model for the challenges. Whenever a challenge is updated, added or deleted from the backend, the model is updated and notifies the Consumer so that the front end can be modified. 
 */
class ChallengeModel extends ChangeNotifier {
  Map<String, ChallengeDto> _challengesById = {};
  ApiClient _client;

  ChallengeModel(ApiClient client) : _client = client {
    /**
     * Stream that listens to updates on the challenges. Challenges can be either deleted or updated. 
     */
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

  /**
   * id: The id of the challenge to be retrieved.
   * 
   * If the id of the challenge is not found in the model, the client requests the challenge data from the server. When the data is retrieved, the challengeModel will listen and update its information, notifying the front end through Consumers. If found, it will return the challenge.
   */
  ChallengeDto? getChallengeById(String id) {
    final chal = _challengesById[id];
    if (chal == null) {
      _client.serverApi
          ?.requestChallengeData(RequestChallengeDataDto(challenges: [id]));
    }
    return chal;
  }
}
