enum UserDataAuthTypeDto { DEVICE, APPLE, GOOGLE }

class UserDto {
  UserDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    username = fields["username"];
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
  dynamic user = "";
  bool deleted = false;
}

class RewardDto {
  RewardDto.fromJson(Map<String, dynamic> fields) {
    id = fields["rewardId"];
    eventId = fields["eventId"];
    userId = fields["userId"];
    description = fields["description"];
    redeemInfo = fields["redeemInfo"];
    isRedeemed = fields["isRedeemed"];
  }
  String id = "";
  String eventId = "";
  String description = "";
  String userId = "";
  String redeemInfo = "";
  bool isRedeemed = false;
}

class UpdateRewardDataDto {
  UpdateRewardDataDto.fromJson(Map<String, dynamic> fields) {
    reward = fields["reward"] is String
        ? fields["reward"]
        : RewardDto.fromJson(fields);
    deleted = fields["deleted"];
  }
  dynamic reward = "";
  bool deleted = false;
}

class RequestRewardDataDto {
  RequestRewardDataDto.fromJson(Map<String, dynamic> fields) {
    rewardIds = fields["rewardIds"];
  }
  List<String> rewardIds = [];
}

enum EventRewardTypeDto {
  PERPETUAL,
  LIMITED_TIME_EVENT,
}

class EventDto {
  EventDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    requiredMembers = fields["requiredMembers"];
    name = fields["name"];
    description = fields["description"];
    reward = fields["rewardType"] == "limited_time"
        ? EventRewardTypeDto.LIMITED_TIME_EVENT
        : EventRewardTypeDto.PERPETUAL;
    endTime = (reward == EventRewardTypeDto.LIMITED_TIME_EVENT
        ? fields["endTime"]
        : null);
    rewardIds = fields["rewardIds"];
    challengeIds = fields["challengeIds"];
    initialOrganizationId = fields["initialOrganizationId"];
    defaultChallengeId = fields["defaultChallengeId"];
    minimumScore = fields["minimumScore"];
    indexable = fields["indexable"];
  }
  String id = "";
  int requiredMembers = 0;
  String name = "";
  String description = "";
  EventRewardTypeDto reward = EventRewardTypeDto.PERPETUAL;
  String endTime = "";
  List<String> rewardIds = [];
  List<String> challengeIds = [];
  String initialOrganizationId = "";
  String defaultChallengeId = "";
  int minimumScore = 0;
  bool indexable = false;
}

class UpdateEventDataDto {
  UpdateEventDataDto.fromJson(Map<String, dynamic> fields) {
    event =
        fields["event"] is String ? fields["event"] : EventDto.fromJson(fields);
    deleted = fields["deleted"];
  }
  dynamic event = null;
  bool deleted = false;
}

class EventTrackerDto {
  EventTrackerDto.fromJson(Map<String, dynamic> fields) {
    eventId = fields['eventId'];
    isRanked = fields['isRanked'];
    curChallengeId = fields['curChallengeId'];
    prevChallengeIds = fields['prevChallengeIds'];
    prevChallengeDates = fields['prevChallengeDates'];
  }
  String eventId = "";
  bool isRanked = false;
  String curChallengeId = "";
  List<String> prevChallengeIds = [];
  List<String> prevChallengeDates = [];
}

class UpdateEventTrackerDataDto {
  UpdateEventTrackerDataDto.fromJson(Map<String, dynamic> fields) {
    tracker = EventTrackerDto.fromJson(fields);
  }
  EventTrackerDto? tracker = null;
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
