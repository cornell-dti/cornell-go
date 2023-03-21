enum UserDataAuthTypeDto { DEVICE, APPLE, GOOGLE }

class UserDto {
  UserDto.fromJson(Map<String, dynamic> fields) {
    fields = fields["user"];
    id = fields["id"];
    username = fields["username"] ?? "NA";
    major = fields["major"] ?? "NA";
    year = fields["year"] ?? "NA";
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

class RewardDTO {
  //Represents a Reward
  RewardDTO.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    eventId = fields["eventId"];
    description = fields["description"];
    userId = fields["userId"];
    redeemInfo = fields["redeemInfo"];
    isRedeemed = fields["isRedeemed"];
    isAchievement = fields["isAchievement"];
    points = fields["points"];
  }

  String id = "";
  String eventId = "";
  String description = "";
  String userId = "";
  String redeemInfo = "";
  bool isRedeemed = false;
  bool isAchievement = false;
  int points = 0;
}

class UpdateRewardDataDto {
  UpdateRewardDataDto.fromJson(Map<String, dynamic> fields) {
    reward = fields["reward"] is String ? null : RewardDTO.fromJson(fields);
    id = fields["reward"] is String ? fields["rewards"] : null;
    deleted = fields["deleted"];
  }
  RewardDTO? reward = null;
  String? id = "";
  bool deleted = false;
}

class RequestRewardDataDto {
  RequestRewardDataDto.fromJson(Map<String, dynamic> fields) {
    rewardIds = fields["rewards"]
        .map<RewardDTO>((dynamic reward) => RewardDTO.fromJson(reward))
        .toList();
  }

  List<UpdateRewardDataDto> rewardIds = [];
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

// Group DTOS
class GroupMemberDto {
  GroupMemberDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    name = fields["name"];
    points = fields["points"];
    curChallengeId = fields["curChallengeId"];
  }
  String id = "";
  String name = "";
  int points = 0;
  String curChallengeId = "";
}

class GroupDto {
  GroupDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    friendlyId = fields["friendlyId"];
    hostId = fields["hostId"];
    curEventId = fields["curEventId"];
    members = fields["members"]
        .map<GroupMemberDto>((dynamic member) => GroupMemberDto.fromJson(member))
        .toList();
  }
  String id = "";
  String friendlyId = "";
  String hostId = "";
  String curEventId = "";
  List<GroupMemberDto> members = [];
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
    if (fields["deleted"]) {
      groupId = fields["group"];
      deleted = fields["deleted"];
    } else {
      group = GroupDto.fromJson(fields["group"]);
    }
  }

  String groupId = "";
  GroupDto? group = null;
  bool deleted = false;
}

//Event DTOs

class EventDto {
  EventDto.fromJson(Map<String, dynamic> fields){
 id = fields['id'];
        requiredMembers = fields['requiredMembers'];
        name = fields['name'];
        description = fields['description'];
        rewardType = fields['rewardType'];
        endTime = fields['endTime'];
        rewardIds = List<String>.from(fields['rewardIds'];
        challengeIds = List<String>.from(fields['challengeIds']);
        initialOrganizationId = fields['initialOrganizationId']);
        defaultChallengeId = fields['defaultChallengeId'];
        minimumScore = fields['minimumScore'];
        indexable = fields['indexable'];
        longitude = fields['longitude'];
        latitude = fields['latitude'];
  }
     

  String id = '';
  int requiredMembers = 0;
  String name = '';
  String description = '';
  String rewardType = '';
  String endTime = '';
  List<String> rewardIds = [];
  List<String> challengeIds = [];
  String? initialOrganizationId = '';
  String defaultChallengeId = '';
  int minimumScore = 0;
  bool indexable = false;
  double longitude = 0.0;
  double latitude = 0.0;
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

class EventTrackerDto {
  String eventId = '';
  bool isRanked = false;
  String curChallengeId = '';
  List<String> prevChallengeIds = [];
  List<String> prevChallengeDates = [];
  
  EventTrackerDto.fromJson(Map<String, dynamic> fields) {
    eventId = fields['eventId'] ?? '';
    isRanked = fields['isRanked'] ?? false;
    curChallengeId = fields['curChallengeId'] ?? '';
    prevChallengeIds = List<String>.from(fields['prevChallengeIds'] ?? []);
    prevChallengeDates = List<String>.from(fields['prevChallengeDates'] ?? []);
  }
}



class UpdateEventTrackerDataDto {
  UpdateEventTrackerDataDto.fromJson(Map<String, dynamic> fields) {
    tracker = EventTrackerDto.fromJson(fields["tracker"]);
  }

 EventTrackerDto? tracker = null;
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

class OrganizationDto {
  OrganizationDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    name = fields["name"];
    accessCode = fields["accessCode"];
    members = fields["members"];
    events = fields["events"];
    defaultEventId = fields["defaultEventId"];
    members = fields["members"];
  }
  String id = "";
  String name = "";
  String accessCode = "";
  List<String> members = [];
  List<String> events = [];
  String defaultEventId = "";
}

class UpdateOrganizationDataDto {
  UpdateOrganizationDataDto.fromJson(Map<String, dynamic> fields) {
    print(fields);
    if (fields["deleted"]) {
      organizationId = fields["organization"];
      deleted = fields["deleted"];
    } else {
      organization = OrganizationDto.fromJson(fields["group"]);
    }
  }

  String organizationId = "";
  OrganizationDto? organization = null;
  bool deleted = false;
}
