enum UserDataAuthTypeDto { DEVICE, APPLE, GOOGLE }

class UserDto {
  UserDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    username = fields["username"];
    major = fields["major"];
    year = fields["year"];
    score = fields["score"];
    groupId = fields["groupId"];
    rewardIds = fields["rewardIds"].cast<String>();
    trackedEventIds = fields["trackedEventIds"].cast<String>();
    authType = fields["authType"] == "google"
        ? UserDataAuthTypeDto.GOOGLE
        : fields["authType"] == "apple"
            ? UserDataAuthTypeDto.APPLE
            : UserDataAuthTypeDto.DEVICE;
  }
  String id = "";
  String username = "";
  String major = "";
  String year = "";
  int score = 0;
  String groupId = "";
  List<String> rewardIds = [];
  List<String> trackedEventIds = [];
  bool ignoreIdLists = false;
  UserDataAuthTypeDto authType = UserDataAuthTypeDto.DEVICE;
}

class UpdateUserDto {
  UpdateUserDto.fromJson(Map<String, dynamic> fields) {
    user = fields["user"] is String ? fields['user'] : UserDto.fromJson(fields);
    deleted = fields["deleted"];
  }
  UserDto? user = null;
  String? id = null;
  bool deleted = false;
}

// class UpdateUserDataDto {
//   UpdateUserDataDto.fromJson(Map<String, dynamic> fields) {
//     id = fields["id"];
//     username = fields["username"];
//     score = fields["score"];
//     groupId = fields["groupId"];
//     rewardIds = fields["rewardIds"].cast<String>();
//     trackedEventIds = fields["trackedEventIds"].cast<String>();
//     ignoreIdLists = fields["ignoreIdLists"];
//     authType = fields["authType"] == "google"
//         ? UpdateUserDataAuthTypeDto.GOOGLE
//         : fields["authType"] == "apple"
//             ? UpdateUserDataAuthTypeDto.APPLE
//             : UpdateUserDataAuthTypeDto.DEVICE;
//   }

//   String id = "";
//   String username = "";
//   int score = 0;
//   String groupId = "";
//   List<String> rewardIds = [];
//   List<String> trackedEventIds = [];
//   bool ignoreIdLists = false;
//   UpdateUserDataAuthTypeDto authType =
//       UpdateUserDataAuthTypeDto.DEVICE; // device, apple, google
// }

class UserRewardedDto {
  UserRewardedDto.fromJson(Map<String, dynamic> fields) {
    rewardId = fields["rewardId"];
    rewardDescription = fields["rewardDescription"];
  }

  String rewardId = "";
  String rewardDescription = "";
}

class InvalidateDataDto {
  InvalidateDataDto.fromJson(Map<String, dynamic> fields) {
    userRewardData = fields["userRewardData"];
    winnerRewardData = fields["winnerRewardData"];
    userEventData = fields["userEventData"];
    groupData = fields["groupData"];
    challengeData = fields["challengeData"];
    leaderboardData = fields["leaderboardData"];
  }

  bool userRewardData = false;
  bool winnerRewardData = false;
  bool userEventData = false;
  bool groupData = false;
  bool challengeData = false;
  bool leaderboardData = false;
}

class UpdateRewardDataRewardDto {
  UpdateRewardDataRewardDto.fromJson(Map<String, dynamic> fields) {
    rewardId = fields["rewardId"];
    eventId = fields["eventId"];
    description = fields["description"];
    redeemInfo = fields["redeemInfo"];
    isRedeemed = fields["isRedeemed"];
  }

  String rewardId = "";
  String eventId = "";
  String description = "";
  String redeemInfo = "";
  bool isRedeemed = false;
}

class UpdateRewardDataDto {
  UpdateRewardDataDto.fromJson(Map<String, dynamic> fields) {
    rewards = fields["rewards"]
        .map<UpdateRewardDataRewardDto>(
            (dynamic reward) => UpdateRewardDataRewardDto.fromJson(reward))
        .toList();
  }

  List<UpdateRewardDataRewardDto> rewards = [];
}

class UpdateEventDataRewardDto {
  UpdateEventDataRewardDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    description = fields["description"];
  }

  String id = "";
  String description = "";
}

enum UpdateEventDataEventRewardTypeDto {
  PERPETUAL,
  LIMITED_TIME_EVENT,
}

class UpdateEventDataEventDto {
  UpdateEventDataEventDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    skippingEnabled = fields["skippingEnabled"];
    name = fields["name"];
    description = fields["description"];
    switch (fields["rewardType"]) {
      case "perpetual":
        rewardType = UpdateEventDataEventRewardTypeDto.PERPETUAL;
        break;
      case "limited_time_event":
        rewardType = UpdateEventDataEventRewardTypeDto.LIMITED_TIME_EVENT;
        break;
    }
    time = fields["time"] == '' ||
            rewardType == UpdateEventDataEventRewardTypeDto.PERPETUAL
        ? null
        : DateTime.parse(fields["time"]);
    rewards = fields["rewards"]
        .map<UpdateEventDataRewardDto>(
            (dynamic reward) => UpdateEventDataRewardDto.fromJson(reward))
        .toList();
    requiredMembers = fields["requiredMembers"];
    challengeIds = fields["challengeIds"].cast<String>();
  }

  String id = "";
  bool skippingEnabled = false;
  String name = "";
  String description = "";
  UpdateEventDataEventRewardTypeDto rewardType =
      UpdateEventDataEventRewardTypeDto.PERPETUAL;
  DateTime? time = null;
  List<UpdateEventDataRewardDto> rewards = [];
  int requiredMembers = 0;
  List<String> challengeIds = [];
}

class UpdateEventDataDto {
  UpdateEventDataDto.fromJson(Map<String, dynamic> fields) {
    isSearch = fields["isSearch"];
    events = fields["events"]
        .map<UpdateEventDataEventDto>(
            (dynamic event) => UpdateEventDataEventDto.fromJson(event))
        .toList();
  }
  List<UpdateEventDataEventDto> events = [];
  bool isSearch = false;
}

class UpdateLeaderDataUserDto {
  UpdateLeaderDataUserDto.fromJson(Map<String, dynamic> fields) {
    userId = fields["userId"];
    username = fields["username"];
    score = fields["score"];
  }

  String userId = "";
  String username = "";
  int score = 0;
}

class UpdateLeaderDataDto {
  UpdateLeaderDataDto.fromJson(Map<String, dynamic> fields) {
    eventId = fields["eventId"];
    offset = fields["offset"];
    users = fields["users"]
        .map<UpdateLeaderDataUserDto>(
            (dynamic user) => UpdateLeaderDataUserDto.fromJson(user))
        .toList();
  }

  String eventId = "";
  int offset = 0;
  List<UpdateLeaderDataUserDto> users = [];
}

class UpdateGroupDataMemberDto {
  UpdateGroupDataMemberDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    name = fields["name"];
    points = fields["points"];
    host = fields["host"];
    curChallengeId = fields["curChallengeId"];
  }

  String id = "";
  String name = "";
  int points = 0;
  bool host = false;
  String curChallengeId = "";
}

class UpdateGroupDataDto {
  UpdateGroupDataDto.fromJson(Map<String, dynamic> fields) {
    curEventId = fields["curEventId"];
    members = fields["members"]
        .map<UpdateGroupDataMemberDto>(
            (dynamic member) => UpdateGroupDataMemberDto.fromJson(member))
        .toList();
    removeListedMembers = fields["removeListedMembers"];
  }

  String curEventId = "";
  List<UpdateGroupDataMemberDto> members = [];
  bool removeListedMembers = false;
}

class UpdateEventTrackerDataEventTrackerDto {
  UpdateEventTrackerDataEventTrackerDto.fromJson(Map<String, dynamic> fields) {
    eventId = fields["eventId"];
    isRanked = fields["isRanked"];
    cooldownMinimum = DateTime.parse(fields["cooldownMinimum"]);
    curChallengeId = fields["curChallengeId"];
    prevChallengeIds = fields["prevChallengeIds"].cast<String>();
  }

  String eventId = "";
  bool isRanked = false;
  DateTime cooldownMinimum = DateTime.now();
  String curChallengeId = "";
  List<String> prevChallengeIds = [];
}

class UpdateEventTrackerDataDto {
  UpdateEventTrackerDataDto.fromJson(Map<String, dynamic> fields) {
    eventTrackers = fields["eventTrackers"]
        .map<UpdateEventTrackerDataEventTrackerDto>((dynamic tracker) =>
            UpdateEventTrackerDataEventTrackerDto.fromJson(tracker))
        .toList();
  }

  List<UpdateEventTrackerDataEventTrackerDto> eventTrackers = [];
}

class UpdateChallengeDataChallengeDto {
  UpdateChallengeDataChallengeDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    name = fields["name"];
    description = fields["description"];
    imageUrl = fields["imageUrl"];
    lat = fields["lat"].toDouble();
    long = fields["long"].toDouble();
    awardingRadius = fields["awardingRadius"].toDouble();
    closeRadius = fields["closeRadius"].toDouble();
    completionDate = fields["completionDate"] == ""
        ? null
        : DateTime.parse(fields["completionDate"]);
  }

  String id = "";
  String name = "";
  String description = "";
  String imageUrl = "";
  double lat = 0;
  double long = 0;
  double awardingRadius = 0;
  double closeRadius = 0;
  DateTime? completionDate = DateTime.now();
}

class UpdateChallengeDataDto {
  UpdateChallengeDataDto.fromJson(Map<String, dynamic> fields) {
    challenges = fields["challenges"]
        .map<UpdateChallengeDataChallengeDto>(
            (dynamic chal) => UpdateChallengeDataChallengeDto.fromJson(chal))
        .toList();
  }

  List<UpdateChallengeDataChallengeDto> challenges = [];
}
