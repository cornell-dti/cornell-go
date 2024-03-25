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

class InvalidateDataDto {
  InvalidateDataDto.fromJson(Map<String, dynamic> fields) {
    userEventData = fields["userEventData"];
    groupData = fields["groupData"];
    challengeData = fields["challengeData"];
    leaderboardData = fields["leaderboardData"];
  }

  bool userEventData = false;
  bool groupData = false;
  bool challengeData = false;
  bool leaderboardData = false;
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
        .map<GroupMemberDto>(
            (dynamic member) => GroupMemberDto.fromJson(member))
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
enum TimeLimitationType {
  PERPETUAL,
  LIMITED_TIME,
}

class EventDto {
  EventDto.fromJson(Map<String, dynamic> fields) {
    id = fields['id'];
    requiredMembers = fields['requiredMembers'];
    name = fields['name'];
    description = fields['description'];
    category = fields['category'];
    timeLimitation = fields['timeLimitation'];
    endTime = fields['endTime'];
    challengeIds = List<String>.from(fields['challengeIds']);
    initialOrganizationId = fields['initialOrganizationId'];
    difficulty = fields['difficulty'];
    indexable = fields['indexable'];
    longitude = fields['longitude'];
    latitude = fields['latitude'];
    userFavoriteIds = fields['userFavoriteIds'];
  }

  String id = '';
  int requiredMembers = 0;
  String name = '';
  String description = '';
  String category = '';
  String timeLimitation = '';
  String endTime = '';
  List<String>? userFavoriteIds = [];
  List<String> challengeIds = [];
  String? initialOrganizationId = '';
  int minimumScore = 0;
  String difficulty = '';
  bool indexable = false;
  double longitude = 0.0;
  double latitude = 0.0;
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

class UpdateEventDataDto {
  UpdateEventDataDto({required this.event, this.deleted = false});

  final dynamic event;
  final bool deleted;

  Map<String, dynamic> toJson() => {
        'event': event is String ? event : EventDto.fromJson(event),
        'deleted': deleted,
      };

  UpdateEventDataDto.fromJson(Map<String, dynamic> fields)
      : event = fields['event'] is String
            ? fields['event']
            : EventDto.fromJson(fields['event']),
        deleted = fields['deleted'] ?? false;
}

class UpdateEventTrackerDataDto {
  UpdateEventTrackerDataDto.fromJson(Map<String, dynamic> fields) {
    tracker = EventTrackerDto.fromJson(fields);
  }

  EventTrackerDto? tracker = null;
}

class ChallengeDto {
  ChallengeDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    name = fields["name"];
    location = fields["location"];
    description = fields["description"];
    points = fields["points"];
    imageUrl = fields["imageUrl"];
    lat = fields["lat"].toDouble();
    long = fields["long"].toDouble();
    awardingRadius = fields["awardingRadius"].toDouble();
    closeRadius = fields["closeRadius"].toDouble();
    containingEventId = fields["containingEventId"];
  }

  String id = "";
  String name = "";
  String location = "";
  String description = "";
  int points = 0;
  String imageUrl = "";
  double lat = 0.0;
  double long = 0.0;
  double awardingRadius = 0.0;
  double closeRadius = 0.0;
  String containingEventId = "";
}

class UpdateChallengeDataDto {
  UpdateChallengeDataDto.fromJson(Map<String, dynamic> fields) {
    if (fields["challenge"] is String) {
      challengeId = fields["challenge"];
    } else {
      challenge = ChallengeDto.fromJson(fields["challenge"]);
    }
    deleted = fields["deleted"] ?? false;
  }
  String? challengeId = "";
  ChallengeDto? challenge = null;
  bool deleted = false;
}

class RequestChallengeDataDto {
  RequestChallengeDataDto.fromJson(Map<String, dynamic> fields) {
    challengeIds = fields['challengeIds'];
  }
  List<String> challengeIds = [];
}

class OrganizationDto {
  OrganizationDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    name = fields["name"];
    accessCode = fields["accessCode"];
    members = fields["members"];
    events = fields["events"];
    members = fields["members"];
  }
  String id = "";
  String name = "";
  String accessCode = "";
  List<String> members = [];
  List<String> events = [];
}

class UpdateOrganizationDataDto {
  UpdateOrganizationDataDto.fromJson(Map<String, dynamic> fields) {
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
