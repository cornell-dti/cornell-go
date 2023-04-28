import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class ChallengeModel extends ChangeNotifier {
  Map<String, ChallengeDto> _challengesById = {};
  ApiClient _client;

  ChallengeModel(ApiClient client) : _client = client {
    client.clientApi.updateChallengeDataStream.listen((event) {
      if(event.challengeId!=null){
        //event.challengeId!=null => event to be deleted.
        _challengesById.remove(event.challengeId);
      }else{
        _challengesById[event.challenge!.id] = event.challenge!;
      }
      notifyListeners();
    });


    client.clientApi.connectedStream.listen((event) {
      _challengesById.clear();
      notifyListeners();
    });

    client.clientApi.invalidateDataStream.listen((event) {
      if (event.challengeData) {
        _challengesById.clear();
        notifyListeners();
      }
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
