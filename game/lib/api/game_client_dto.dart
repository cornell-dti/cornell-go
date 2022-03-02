class UpdateUserDataDto {
  String id = "";
  String username = "";
  int score = 0;
  String groupId = "";
  List<String> rewardIds = [];
  List<String> trackedEventIds = [];
  bool ignoreIdsLists = false;
  String authType = "device"; // device, apple, google
}

class UserRewardedDto {
  String rewardId = "";
  String rewardDescription = "";
}

class InvalidateDataDto {
  bool userRewardData = false;
  bool winnerRewardData = false;
  bool userEventData = false;
  bool groupData = false;
  bool challengeData = false;
  bool leaderboardData = false;
}

class UpdateRewardDataRewardDto {
  String eventId = "";
  String description = "";
  String redeemInfo = "";
  bool isRedeemed = false;
}

class UpdateRewardDataDto {
  List<UpdateRewardDataRewardDto> rewards = [];
}

class UpdateEventDataRewardDto {
  String id = "";
  String description = "";
}

class UpdateEventDataEventDto {
  String id = "";
  bool skippingEnabled = false;
  bool hasStarChallenge = false;
  String name = "";
  String description = "";
  // no_rewards, limited_time_event, win_on_completion, race_to_win
  String rewardType = "no_rewards";
  String time = "";
  int topCount = 0;
  List<UpdateEventDataRewardDto> rewards = [];
  int requiredMembers = 0;
  List<String> challengeIds = [];
}

class UpdateLeaderDataUserDto {
  String userId = "";
  String username = "";
  int score = 0;
}

class UpdateLeaderDataDto {
  String eventId = "";
  int offset = 0;
  List<UpdateLeaderDataUserDto> users = [];
}

class UpdateGroupDataMemberDto {
  String id = "";
  String name = "";
  int points = 0;
  bool host = false;
  String curChallengeId = "";
}

class UpdateGroupDataDto {
  String curEventId = "";
  List<UpdateGroupDataMemberDto> members = [];
  bool removeListedMembers = false;
}

class UpdateEventTrackerDataEventTrackerDto {
  String eventId = "";
  bool isRanked = false;
  String cooldownMinimum = "";
  String curChallengeId = "";
  List<String> prevChallengeIds = [];
}

class UpdateEventTrackerDataDto {
  List<UpdateEventTrackerDataEventTrackerDto> eventTrackers = [];
}

class UpdateChallengeDataChallengeDto {
  String id = "";
  String name = "";
  String description = "";
  String imageUrl = "";
  double lat = 0;
  double long = 0;
  double awardingRadius = 0;
  double closeRadius = 0;
  String completionData = "";
}

class UpdateChallengeDataDto {
  List<UpdateChallengeDataChallengeDto> challenges = [];
}
