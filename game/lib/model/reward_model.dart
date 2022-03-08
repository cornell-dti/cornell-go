import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class RewardModel extends ChangeNotifier {
  List<UpdateRewardDataRewardDto> rewards = [];

  RewardModel(ApiClient client) {
    client.clientApi.updateUserDataStream.listen((event) {
      client.serverApi?.requestRewardData(event.rewardIds);
    });

    client.clientApi.updateRewardDataStream.listen((event) {
      rewards = event.rewards;
      notifyListeners();
    });
  }
}
