import 'package:flutter/foundation.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';

class RewardModel extends ChangeNotifier {
  ApiClient _client;
  List<UpdateRewardDataRewardDto> rewards = [];
  Map<String, UpdateRewardDataRewardDto> rewardByEventId = {};

  RewardModel(ApiClient client) : _client = client {
    client.clientApi.updateUserDataStream.listen((event) {
      if (!event.ignoreIdLists) {
        client.serverApi?.requestRewardData(event.rewardIds);
      }
    });

    client.clientApi.updateRewardDataStream.listen((event) {
      rewards = event.rewards;
      event.rewards
          .forEach((element) => rewardByEventId[element.eventId] = element);
      notifyListeners();
    });

    client.clientApi.connectedStream.listen((event) {
      rewards.clear();
      rewardByEventId.clear();
      notifyListeners();
    });

    client.clientApi.invalidateDataStream.listen((event) {
      if (event.userRewardData || event.winnerRewardData) {
        rewards.clear();
        rewardByEventId.clear();
        notifyListeners();
      }
    });
  }

  List<UpdateRewardDataRewardDto> getRewards() {
    return rewards;
  }

  UpdateRewardDataRewardDto? getRewardByEventId(
      String eventId, String rewardId) {
    final reward = rewardByEventId[eventId];
    if (reward != null) {
      return reward;
    } else {
      _client.serverApi?.requestRewardData([rewardId]);
      return null;
    }
  }
}
