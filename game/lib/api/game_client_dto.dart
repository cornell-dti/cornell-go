// CODE AUTOGENERATED BY npm run updateapi
enum LocationType {
  EngQuad,
  ArtsQuad,
  AgQuad,
  NorthCampus,
  WestCampus,
  Collegetown,
  IthacaCommons,
  Any,
}

enum AchievementType {
  TotalPoints,
  TotalChallenges,
  TotalJourneys,
  TotalChallengesOrJourneys,
}

enum AchievementLocationTypeDto {
  ENG_QUAD,
  ARTS_QUAD,
  AG_QUAD,
  NORTH_CAMPUS,
  WEST_CAMPUS,
  COLLEGETOWN,
  IthacaCommons,
  Any,
}

enum AchievementAchievementTypeDto {
  TOTAL_POINTS,
  TOTAL_CHALLENGES,
  TOTAL_JOURNEYS,
  TOTAL_CHALLENGES_OR_JOURNEYS,
}

enum LoginAudDto {
  android,
  ios,
  web,
}

enum LoginEnrollmentTypeDto {
  UNDERGRADUATE,
  GRADUATE,
  FACULTY,
  ALUMNI,
}

enum EventTimeLimitationDto {
  LIMITED_TIME,
  PERPETUAL,
}

enum EventDifficultyDto {
  Easy,
  Normal,
  Hard,
}

enum SetAuthToOAuthProviderDto {
  apple,
  google,
}

enum UserEnrollmentTypeDto {
  UNDERGRADUATE,
  GRADUATE,
  FACULTY,
  ALUMNI,
}

enum UserAuthTypeDto {
  apple,
  google,
  device,
}

class AchievementDto {
  AchievementDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    eventId = fields["eventId"];
    requiredPoints = fields["requiredPoints"];
    name = fields["name"];
    description = fields["description"];
    imageUrl = fields["imageUrl"];
    locationType =
        AchievementLocationTypeDto.values.byName(fields['locationType']);
    achievementType =
        AchievementAchievementTypeDto.values.byName(fields['achievementType']);
    organizations = List<String>.from(fields['organizations']);
  }

  void partialUpdate(AchievementDto other) {
    id = other.id;
    eventId = other.eventId;
    requiredPoints = other.requiredPoints;
    name = other.name;
    description = other.description;
    imageUrl = other.imageUrl;
    locationType = other.locationType;
    achievementType = other.achievementType;
    organizations = other.organizations;
  }

  late String id;
  late String eventId;
  late int requiredPoints;
  late String name;
  late String description;
  late String imageUrl;
  late AchievementLocationTypeDto locationType;
  late AchievementAchievementTypeDto achievementType;
  late List<String> organizations;
}

class AchievementTrackerDto {
  AchievementTrackerDto.fromJson(Map<String, dynamic> fields) {
    userId = fields["userId"];
    progress = fields["progress"];
    achievementId = fields["achievementId"];
    dateComplete = fields['dateComplete'] ? (fields["dateComplete"]) : null;
  }

  void partialUpdate(AchievementTrackerDto other) {
    userId = other.userId;
    progress = other.progress;
    achievementId = other.achievementId;
    dateComplete =
        other.dateComplete == null ? dateComplete : other.dateComplete;
  }

  late String userId;
  late int progress;
  late String achievementId;
  late String? dateComplete;
}

class LoginDto {
  LoginDto.fromJson(Map<String, dynamic> fields) {
    idToken = fields["idToken"];
    lat = fields["lat"];
    long = fields["long"];
    username = fields['username'] ? (fields["username"]) : null;
    year = fields['year'] ? (fields["year"]) : null;
    aud = fields['aud'] ? (LoginAudDto.values.byName(fields['aud'])) : null;
    enrollmentType =
        LoginEnrollmentTypeDto.values.byName(fields['enrollmentType']);
  }

  void partialUpdate(LoginDto other) {
    idToken = other.idToken;
    lat = other.lat;
    long = other.long;
    username = other.username == null ? username : other.username;
    year = other.year == null ? year : other.year;
    aud = other.aud == null ? aud : other.aud;
    enrollmentType = other.enrollmentType;
  }

  late String idToken;
  late int lat;
  late int long;
  late String? username;
  late String? year;
  late LoginAudDto? aud;
  late LoginEnrollmentTypeDto enrollmentType;
}

class RefreshTokenDto {
  RefreshTokenDto.fromJson(Map<String, dynamic> fields) {
    refreshToken = fields["refreshToken"];
  }

  void partialUpdate(RefreshTokenDto other) {
    refreshToken = other.refreshToken;
  }

  late String refreshToken;
}

class CompletedChallengeDto {
  CompletedChallengeDto.fromJson(Map<String, dynamic> fields) {
    challengeId = fields["challengeId"];
  }

  void partialUpdate(CompletedChallengeDto other) {
    challengeId = other.challengeId;
  }

  late String challengeId;
}

class ChallengeDto {
  ChallengeDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    name = fields['name'] ? (fields["name"]) : null;
    location = fields['location'] ? (fields["location"]) : null;
    description = fields['description'] ? (fields["description"]) : null;
    points = fields['points'] ? (fields["points"]) : null;
    imageUrl = fields['imageUrl'] ? (fields["imageUrl"]) : null;
    latF = fields['latF'] ? (fields["latF"]) : null;
    longF = fields['longF'] ? (fields["longF"]) : null;
    awardingRadiusF =
        fields['awardingRadiusF'] ? (fields["awardingRadiusF"]) : null;
    closeRadiusF = fields['closeRadiusF'] ? (fields["closeRadiusF"]) : null;
    containingEventId =
        fields['containingEventId'] ? (fields["containingEventId"]) : null;
  }

  void partialUpdate(ChallengeDto other) {
    id = other.id;
    name = other.name == null ? name : other.name;
    location = other.location == null ? location : other.location;
    description = other.description == null ? description : other.description;
    points = other.points == null ? points : other.points;
    imageUrl = other.imageUrl == null ? imageUrl : other.imageUrl;
    latF = other.latF == null ? latF : other.latF;
    longF = other.longF == null ? longF : other.longF;
    awardingRadiusF =
        other.awardingRadiusF == null ? awardingRadiusF : other.awardingRadiusF;
    closeRadiusF =
        other.closeRadiusF == null ? closeRadiusF : other.closeRadiusF;
    containingEventId = other.containingEventId == null
        ? containingEventId
        : other.containingEventId;
  }

  late String id;
  late String? name;
  late String? location;
  late String? description;
  late int? points;
  late String? imageUrl;
  late double? latF;
  late double? longF;
  late double? awardingRadiusF;
  late double? closeRadiusF;
  late String? containingEventId;
}

class RequestChallengeDataDto {
  RequestChallengeDataDto.fromJson(Map<String, dynamic> fields) {
    challenges = List<String>.from(fields['challenges']);
  }

  void partialUpdate(RequestChallengeDataDto other) {
    challenges = other.challenges;
  }

  late List<String> challenges;
}

class UpdateChallengeDataDto {
  UpdateChallengeDataDto.fromJson(Map<String, dynamic> fields) {
    challenge = ChallengeDto.fromJson(fields['challenge']);
    deleted = fields["deleted"];
  }

  void partialUpdate(UpdateChallengeDataDto other) {
    challenge = other.challenge;
    deleted = other.deleted;
  }

  late ChallengeDto challenge;
  late bool deleted;
}

class RequestEventTrackerDataDto {
  RequestEventTrackerDataDto.fromJson(Map<String, dynamic> fields) {
    trackedEvents = List<String>.from(fields['trackedEvents']);
  }

  void partialUpdate(RequestEventTrackerDataDto other) {
    trackedEvents = other.trackedEvents;
  }

  late List<String> trackedEvents;
}

class SetCurrentChallengeDto {
  SetCurrentChallengeDto.fromJson(Map<String, dynamic> fields) {
    challengeId = fields["challengeId"];
  }

  void partialUpdate(SetCurrentChallengeDto other) {
    challengeId = other.challengeId;
  }

  late String challengeId;
}

class LeaderDto {
  LeaderDto.fromJson(Map<String, dynamic> fields) {
    userId = fields["userId"];
    username = fields["username"];
    score = fields["score"];
  }

  void partialUpdate(LeaderDto other) {
    userId = other.userId;
    username = other.username;
    score = other.score;
  }

  late String userId;
  late String username;
  late int score;
}

class UpdateLeaderDataDto {
  UpdateLeaderDataDto.fromJson(Map<String, dynamic> fields) {
    eventId = fields["eventId"];
    offset = fields["offset"];
    users = fields["users"]
        .map<LeaderDto>((dynamic val) => LeaderDto.fromJson(val))
        .toList();
  }

  void partialUpdate(UpdateLeaderDataDto other) {
    eventId = other.eventId;
    offset = other.offset;
    users = other.users;
  }

  late String eventId;
  late int offset;
  late List<LeaderDto> users;
}

class UpdateErrorDto {
  UpdateErrorDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    message = fields["message"];
  }

  void partialUpdate(UpdateErrorDto other) {
    id = other.id;
    message = other.message;
  }

  late String id;
  late String message;
}

class RequestAllEventDataDto {
  RequestAllEventDataDto.fromJson(Map<String, dynamic> fields) {
    offset = fields["offset"];
    count = fields["count"];
  }

  void partialUpdate(RequestAllEventDataDto other) {
    offset = other.offset;
    count = other.count;
  }

  late int offset;
  late int count;
}

class RequestEventDataDto {
  RequestEventDataDto.fromJson(Map<String, dynamic> fields) {
    events = fields['events'] ? (List<String>.from(fields['events'])) : null;
  }

  void partialUpdate(RequestEventDataDto other) {
    events = other.events == null ? events : other.events;
  }

  late List<String>? events;
}

class RequestEventLeaderDataDto {
  RequestEventLeaderDataDto.fromJson(Map<String, dynamic> fields) {
    offset = fields["offset"];
    count = fields["count"];
    eventId = fields["eventId"];
  }

  void partialUpdate(RequestEventLeaderDataDto other) {
    offset = other.offset;
    count = other.count;
    eventId = other.eventId;
  }

  late int offset;
  late int count;
  late String eventId;
}

class RequestRecommendedEventsDto {
  RequestRecommendedEventsDto.fromJson(Map<String, dynamic> fields) {
    latitudeF = fields["latitudeF"];
    longitudeF = fields["longitudeF"];
    count = fields['count'] ? (fields["count"]) : null;
  }

  void partialUpdate(RequestRecommendedEventsDto other) {
    latitudeF = other.latitudeF;
    longitudeF = other.longitudeF;
    count = other.count == null ? count : other.count;
  }

  late double latitudeF;
  late double longitudeF;
  late int? count;
}

class EventDto {
  EventDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    requiredMembers =
        fields['requiredMembers'] ? (fields["requiredMembers"]) : null;
    name = fields['name'] ? (fields["name"]) : null;
    description = fields['description'] ? (fields["description"]) : null;
    timeLimitation = fields['timeLimitation']
        ? (EventTimeLimitationDto.values.byName(fields['timeLimitation']))
        : null;
    endTime = fields['endTime'] ? (fields["endTime"]) : null;
    challenges =
        fields['challenges'] ? (List<String>.from(fields['challenges'])) : null;
    userFavorites = fields['userFavorites']
        ? (List<String>.from(fields['userFavorites']))
        : null;
    initialOrganizationId = fields['initialOrganizationId']
        ? (fields["initialOrganizationId"])
        : null;
    difficulty = fields['difficulty']
        ? (EventDifficultyDto.values.byName(fields['difficulty']))
        : null;
    indexable = fields['indexable'] ? (fields["indexable"]) : null;
    longitudeF = fields['longitudeF'] ? (fields["longitudeF"]) : null;
    latitudeF = fields['latitudeF'] ? (fields["latitudeF"]) : null;
  }

  void partialUpdate(EventDto other) {
    id = other.id;
    requiredMembers =
        other.requiredMembers == null ? requiredMembers : other.requiredMembers;
    name = other.name == null ? name : other.name;
    description = other.description == null ? description : other.description;
    timeLimitation =
        other.timeLimitation == null ? timeLimitation : other.timeLimitation;
    endTime = other.endTime == null ? endTime : other.endTime;
    challenges = other.challenges == null ? challenges : other.challenges;
    userFavorites =
        other.userFavorites == null ? userFavorites : other.userFavorites;
    initialOrganizationId = other.initialOrganizationId == null
        ? initialOrganizationId
        : other.initialOrganizationId;
    difficulty = other.difficulty == null ? difficulty : other.difficulty;
    indexable = other.indexable == null ? indexable : other.indexable;
    longitudeF = other.longitudeF == null ? longitudeF : other.longitudeF;
    latitudeF = other.latitudeF == null ? latitudeF : other.latitudeF;
  }

  late String id;
  late int? requiredMembers;
  late String? name;
  late String? description;
  late EventTimeLimitationDto? timeLimitation;
  late String? endTime;
  late List<String>? challenges;
  late List<String>? userFavorites;
  late String? initialOrganizationId;
  late EventDifficultyDto? difficulty;
  late bool? indexable;
  late double? longitudeF;
  late double? latitudeF;
}

class EventTrackerDto {
  EventTrackerDto.fromJson(Map<String, dynamic> fields) {
    eventId = fields["eventId"];
    isRanked = fields['isRanked'] ? (fields["isRanked"]) : null;
    curChallengeId =
        fields['curChallengeId'] ? (fields["curChallengeId"]) : null;
    prevChallenges = fields['prevChallenges']
        ? (List<String>.from(fields['prevChallenges']))
        : null;
    prevChallengeDates = fields['prevChallengeDates']
        ? (List<String>.from(fields['prevChallengeDates']))
        : null;
  }

  void partialUpdate(EventTrackerDto other) {
    eventId = other.eventId;
    isRanked = other.isRanked == null ? isRanked : other.isRanked;
    curChallengeId =
        other.curChallengeId == null ? curChallengeId : other.curChallengeId;
    prevChallenges =
        other.prevChallenges == null ? prevChallenges : other.prevChallenges;
    prevChallengeDates = other.prevChallengeDates == null
        ? prevChallengeDates
        : other.prevChallengeDates;
  }

  late String eventId;
  late bool? isRanked;
  late String? curChallengeId;
  late List<String>? prevChallenges;
  late List<String>? prevChallengeDates;
}

class UpdateEventTrackerDataDto {
  UpdateEventTrackerDataDto.fromJson(Map<String, dynamic> fields) {
    tracker = EventTrackerDto.fromJson(fields['tracker']);
  }

  void partialUpdate(UpdateEventTrackerDataDto other) {
    tracker = other.tracker;
  }

  late EventTrackerDto tracker;
}

class UpdateEventDataDto {
  UpdateEventDataDto.fromJson(Map<String, dynamic> fields) {
    event = EventDto.fromJson(fields['event']);
    deleted = fields["deleted"];
  }

  void partialUpdate(UpdateEventDataDto other) {
    event = other.event;
    deleted = other.deleted;
  }

  late EventDto event;
  late bool deleted;
}

class JoinGroupDto {
  JoinGroupDto.fromJson(Map<String, dynamic> fields) {
    groupId = fields["groupId"];
  }

  void partialUpdate(JoinGroupDto other) {
    groupId = other.groupId;
  }

  late String groupId;
}

class LeaveGroupDto {
  LeaveGroupDto.fromJson(Map<String, dynamic> fields) {}

  void partialUpdate(LeaveGroupDto other) {}
}

class RequestGroupDataDto {
  RequestGroupDataDto.fromJson(Map<String, dynamic> fields) {}

  void partialUpdate(RequestGroupDataDto other) {}
}

class SetCurrentEventDto {
  SetCurrentEventDto.fromJson(Map<String, dynamic> fields) {
    eventId = fields["eventId"];
  }

  void partialUpdate(SetCurrentEventDto other) {
    eventId = other.eventId;
  }

  late String eventId;
}

class GroupMemberDto {
  GroupMemberDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    name = fields["name"];
    points = fields["points"];
    curChallengeId = fields["curChallengeId"];
  }

  void partialUpdate(GroupMemberDto other) {
    id = other.id;
    name = other.name;
    points = other.points;
    curChallengeId = other.curChallengeId;
  }

  late String id;
  late String name;
  late int points;
  late String curChallengeId;
}

class GroupDto {
  GroupDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    friendlyId = fields['friendlyId'] ? (fields["friendlyId"]) : null;
    hostId = fields['hostId'] ? (fields["hostId"]) : null;
    curEventId = fields['curEventId'] ? (fields["curEventId"]) : null;
    members = fields['members']
        ? (fields["members"]
            .map<GroupMemberDto>((dynamic val) => GroupMemberDto.fromJson(val))
            .toList())
        : null;
  }

  void partialUpdate(GroupDto other) {
    id = other.id;
    friendlyId = other.friendlyId == null ? friendlyId : other.friendlyId;
    hostId = other.hostId == null ? hostId : other.hostId;
    curEventId = other.curEventId == null ? curEventId : other.curEventId;
    members = other.members == null ? members : other.members;
  }

  late String id;
  late String? friendlyId;
  late String? hostId;
  late String? curEventId;
  late List<GroupMemberDto>? members;
}

class UpdateGroupDataDto {
  UpdateGroupDataDto.fromJson(Map<String, dynamic> fields) {
    group = GroupDto.fromJson(fields['group']);
    deleted = fields["deleted"];
  }

  void partialUpdate(UpdateGroupDataDto other) {
    group = other.group;
    deleted = other.deleted;
  }

  late GroupDto group;
  late bool deleted;
}

class GroupInviteDto {
  GroupInviteDto.fromJson(Map<String, dynamic> fields) {
    groupId = fields["groupId"];
    username = fields["username"];
  }

  void partialUpdate(GroupInviteDto other) {
    groupId = other.groupId;
    username = other.username;
  }

  late String groupId;
  late String username;
}

class SendGroupInviteDto {
  SendGroupInviteDto.fromJson(Map<String, dynamic> fields) {
    targetUsername = fields["targetUsername"];
  }

  void partialUpdate(SendGroupInviteDto other) {
    targetUsername = other.targetUsername;
  }

  late String targetUsername;
}

class OrganizationDto {
  OrganizationDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    name = fields['name'] ? (fields["name"]) : null;
    accessCode = fields['accessCode'] ? (fields["accessCode"]) : null;
    members = fields['members'] ? (List<String>.from(fields['members'])) : null;
    events = fields['events'] ? (List<String>.from(fields['events'])) : null;
    managers =
        fields['managers'] ? (List<String>.from(fields['managers'])) : null;
  }

  void partialUpdate(OrganizationDto other) {
    id = other.id;
    name = other.name == null ? name : other.name;
    accessCode = other.accessCode == null ? accessCode : other.accessCode;
    members = other.members == null ? members : other.members;
    events = other.events == null ? events : other.events;
    managers = other.managers == null ? managers : other.managers;
  }

  late String id;
  late String? name;
  late String? accessCode;
  late List<String>? members;
  late List<String>? events;
  late List<String>? managers;
}

class RequestOrganizationDataDto {
  RequestOrganizationDataDto.fromJson(Map<String, dynamic> fields) {
    admin = fields["admin"];
  }

  void partialUpdate(RequestOrganizationDataDto other) {
    admin = other.admin;
  }

  late bool admin;
}

class UpdateOrganizationDataDto {
  UpdateOrganizationDataDto.fromJson(Map<String, dynamic> fields) {
    organization = OrganizationDto.fromJson(fields['organization']);
    deleted = fields["deleted"];
  }

  void partialUpdate(UpdateOrganizationDataDto other) {
    organization = other.organization;
    deleted = other.deleted;
  }

  late OrganizationDto organization;
  late bool deleted;
}

class CloseAccountDto {
  CloseAccountDto.fromJson(Map<String, dynamic> fields) {}

  void partialUpdate(CloseAccountDto other) {}
}

class SetUsernameDto {
  SetUsernameDto.fromJson(Map<String, dynamic> fields) {
    newUsername = fields["newUsername"];
  }

  void partialUpdate(SetUsernameDto other) {
    newUsername = other.newUsername;
  }

  late String newUsername;
}

class SetMajorDto {
  SetMajorDto.fromJson(Map<String, dynamic> fields) {
    newMajor = fields["newMajor"];
  }

  void partialUpdate(SetMajorDto other) {
    newMajor = other.newMajor;
  }

  late String newMajor;
}

class SetGraduationYearDto {
  SetGraduationYearDto.fromJson(Map<String, dynamic> fields) {
    newYear = fields["newYear"];
  }

  void partialUpdate(SetGraduationYearDto other) {
    newYear = other.newYear;
  }

  late String newYear;
}

class BanUserDto {
  BanUserDto.fromJson(Map<String, dynamic> fields) {
    userId = fields["userId"];
    isBanned = fields["isBanned"];
  }

  void partialUpdate(BanUserDto other) {
    userId = other.userId;
    isBanned = other.isBanned;
  }

  late String userId;
  late bool isBanned;
}

class SetAuthToOAuthDto {
  SetAuthToOAuthDto.fromJson(Map<String, dynamic> fields) {
    provider = SetAuthToOAuthProviderDto.values.byName(fields['provider']);
    authId = fields["authId"];
  }

  void partialUpdate(SetAuthToOAuthDto other) {
    provider = other.provider;
    authId = other.authId;
  }

  late SetAuthToOAuthProviderDto provider;
  late String authId;
}

class SetAuthToDeviceDto {
  SetAuthToDeviceDto.fromJson(Map<String, dynamic> fields) {
    deviceId = fields["deviceId"];
  }

  void partialUpdate(SetAuthToDeviceDto other) {
    deviceId = other.deviceId;
  }

  late String deviceId;
}

class RequestGlobalLeaderDataDto {
  RequestGlobalLeaderDataDto.fromJson(Map<String, dynamic> fields) {
    offset = fields["offset"];
    count = fields["count"];
  }

  void partialUpdate(RequestGlobalLeaderDataDto other) {
    offset = other.offset;
    count = other.count;
  }

  late int offset;
  late int count;
}

class RequestUserDataDto {
  RequestUserDataDto.fromJson(Map<String, dynamic> fields) {
    userId = fields['userId'] ? (fields["userId"]) : null;
  }

  void partialUpdate(RequestUserDataDto other) {
    userId = other.userId == null ? userId : other.userId;
  }

  late String? userId;
}

class RequestAllUserDataDto {
  RequestAllUserDataDto.fromJson(Map<String, dynamic> fields) {}

  void partialUpdate(RequestAllUserDataDto other) {}
}

class RequestFavoriteEventDataDto {
  RequestFavoriteEventDataDto.fromJson(Map<String, dynamic> fields) {
    isFavorite = fields["isFavorite"];
    eventId = fields["eventId"];
  }

  void partialUpdate(RequestFavoriteEventDataDto other) {
    isFavorite = other.isFavorite;
    eventId = other.eventId;
  }

  late bool isFavorite;
  late String eventId;
}

class UserDto {
  UserDto.fromJson(Map<String, dynamic> fields) {
    id = fields["id"];
    username = fields['username'] ? (fields["username"]) : null;
    enrollmentType = fields['enrollmentType']
        ? (UserEnrollmentTypeDto.values.byName(fields['enrollmentType']))
        : null;
    email = fields['email'] ? (fields["email"]) : null;
    year = fields['year'] ? (fields["year"]) : null;
    score = fields['score'] ? (fields["score"]) : null;
    isBanned = fields['isBanned'] ? (fields["isBanned"]) : null;
    groupId = fields['groupId'] ? (fields["groupId"]) : null;
    authType = fields['authType']
        ? (UserAuthTypeDto.values.byName(fields['authType']))
        : null;
    trackedEvents = fields['trackedEvents']
        ? (List<String>.from(fields['trackedEvents']))
        : null;
    favorites =
        fields['favorites'] ? (List<String>.from(fields['favorites'])) : null;
  }

  void partialUpdate(UserDto other) {
    id = other.id;
    username = other.username == null ? username : other.username;
    enrollmentType =
        other.enrollmentType == null ? enrollmentType : other.enrollmentType;
    email = other.email == null ? email : other.email;
    year = other.year == null ? year : other.year;
    score = other.score == null ? score : other.score;
    isBanned = other.isBanned == null ? isBanned : other.isBanned;
    groupId = other.groupId == null ? groupId : other.groupId;
    authType = other.authType == null ? authType : other.authType;
    trackedEvents =
        other.trackedEvents == null ? trackedEvents : other.trackedEvents;
    favorites = other.favorites == null ? favorites : other.favorites;
  }

  late String id;
  late String? username;
  late UserEnrollmentTypeDto? enrollmentType;
  late String? email;
  late String? year;
  late int? score;
  late bool? isBanned;
  late String? groupId;
  late UserAuthTypeDto? authType;
  late List<String>? trackedEvents;
  late List<String>? favorites;
}

class UpdateUserDataDto {
  UpdateUserDataDto.fromJson(Map<String, dynamic> fields) {
    user = UserDto.fromJson(fields['user']);
    deleted = fields["deleted"];
  }

  void partialUpdate(UpdateUserDataDto other) {
    user = other.user;
    deleted = other.deleted;
  }

  late UserDto user;
  late bool deleted;
}
