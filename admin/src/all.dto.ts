// CODE AUTOGENERATED BY npm run updateapi
// IF YOU MODIFY THIS FILE, MAKE SURE TO ALSO MODIFY THE updateapi SCRIPT!
// OTHERWISE YOUR CHANGES MAY BE OVERWRITTEN!
type LocationType =
  | "EngQuad"
  | "ArtsQuad"
  | "AgQuad"
  | "NorthCampus"
  | "WestCampus"
  | "Collegetown"
  | "IthacaCommons"
  | "Any";

type AchievementType =
  | "TotalPoints"
  | "TotalChallenges"
  | "TotalJourneys"
  | "TotalChallengesOrJourneys";

type AchievementLocationTypeDto =
  | "ENG_QUAD"
  | "ARTS_QUAD"
  | "AG_QUAD"
  | "NORTH_CAMPUS"
  | "WEST_CAMPUS"
  | "COLLEGETOWN"
  | "IthacaCommons"
  | "Any";

type AchievementAchievementTypeDto =
  | "TOTAL_POINTS"
  | "TOTAL_CHALLENGES"
  | "TOTAL_JOURNEYS"
  | "TOTAL_CHALLENGES_OR_JOURNEYS";

type LoginAudDto = "android" | "ios" | "web";

type LoginEnrollmentTypeDto =
  | "UNDERGRADUATE"
  | "GRADUATE"
  | "FACULTY"
  | "ALUMNI";

type EventTimeLimitationDto = "LIMITED_TIME" | "PERPETUAL";

type EventDifficultyDto = "Easy" | "Normal" | "Hard";

type SetAuthToOAuthProviderDto = "apple" | "google";

type UserEnrollmentTypeDto =
  | "UNDERGRADUATE"
  | "GRADUATE"
  | "FACULTY"
  | "ALUMNI";

type UserAuthTypeDto = "apple" | "google" | "device";

export interface AchievementDto {
  id: string;
  eventId: string;
  requiredPoints: number;
  name: string;
  description: string;
  imageUrl: string;
  locationType: AchievementLocationTypeDto;
  achievementType: AchievementAchievementTypeDto;
  organizations: string[];
}

export interface AchievementTrackerDto {
  userId: string;
  progress: number;
  achievementId: string;
  dateComplete?: string;
}

export interface LoginDto {
  idToken: string;
  lat: number;
  long: number;
  username?: string;
  year?: string;
  aud?: LoginAudDto;
  enrollmentType: LoginEnrollmentTypeDto;
}

export interface RefreshTokenDto {
  refreshToken: string;
}

export interface CompletedChallengeDto {
  challengeId: string;
}

export interface ChallengeDto {
  id: string;
  name?: string;
  location?: string;
  description?: string;
  points?: number;
  imageUrl?: string;
  latF?: number;
  longF?: number;
  awardingRadiusF?: number;
  closeRadiusF?: number;
  linkedEventId?: string;
}

export interface RequestChallengeDataDto {
  challenges: string[];
}

export interface UpdateChallengeDataDto {
  challenge: ChallengeDto;
  deleted: boolean;
}

export interface RequestEventTrackerDataDto {
  trackedEvents: string[];
}

export interface SetCurrentChallengeDto {
  challengeId: string;
}

export interface LeaderDto {
  userId: string;
  username: string;
  score: number;
}

export interface UpdateLeaderDataDto {
  eventId: string;
  offset: number;
  users: LeaderDto[];
}

export interface UpdateErrorDto {
  id: string;
  message: string;
}

export interface RequestAllEventDataDto {
  offset: number;
  count: number;
}

export interface RequestEventDataDto {
  events?: string[];
}

export interface RequestEventLeaderDataDto {
  offset: number;
  count: number;
  eventId: string;
}

export interface RequestRecommendedEventsDto {
  latitudeF: number;
  longitudeF: number;
  count?: number;
}

export interface EventDto {
  id: string;
  requiredMembers?: number;
  name?: string;
  description?: string;
  timeLimitation?: EventTimeLimitationDto;
  endTime?: string;
  challenges?: string[];
  userFavorites?: string[];
  initialOrganizationId?: string;
  difficulty?: EventDifficultyDto;
  indexable?: boolean;
  longitudeF?: number;
  latitudeF?: number;
}

export interface EventTrackerDto {
  eventId: string;
  isRanked?: boolean;
  curChallengeId?: string;
  prevChallenges?: string[];
  prevChallengeDates?: string[];
}

export interface UpdateEventTrackerDataDto {
  tracker: EventTrackerDto;
}

export interface UpdateEventDataDto {
  event: EventDto;
  deleted: boolean;
}

export interface JoinGroupDto {
  groupId: string;
}

export interface LeaveGroupDto {}

export interface RequestGroupDataDto {}

export interface SetCurrentEventDto {
  eventId: string;
}

export interface GroupMemberDto {
  id: string;
  name: string;
  points: number;
  curChallengeId: string;
}

export interface GroupDto {
  id: string;
  friendlyId?: string;
  hostId?: string;
  curEventId?: string;
  members?: GroupMemberDto[];
}

export interface UpdateGroupDataDto {
  group: GroupDto;
  deleted: boolean;
}

export interface GroupInviteDto {
  groupId: string;
  username: string;
}

export interface SendGroupInviteDto {
  targetUsername: string;
}

export interface OrganizationDto {
  id: string;
  name?: string;
  accessCode?: string;
  members?: string[];
  events?: string[];
  managers?: string[];
}

export interface RequestOrganizationDataDto {
  admin: boolean;
}

export interface UpdateOrganizationDataDto {
  organization: OrganizationDto;
  deleted: boolean;
}

export interface CloseAccountDto {}

export interface SetUsernameDto {
  newUsername: string;
}

export interface SetMajorDto {
  newMajor: string;
}

export interface SetGraduationYearDto {
  newYear: string;
}

export interface BanUserDto {
  userId: string;
  isBanned: boolean;
}

export interface SetAuthToOAuthDto {
  provider: SetAuthToOAuthProviderDto;
  authId: string;
}

export interface SetAuthToDeviceDto {
  deviceId: string;
}

export interface RequestGlobalLeaderDataDto {
  offset: number;
  count: number;
}

export interface RequestUserDataDto {
  userId?: string;
}

export interface RequestAllUserDataDto {}

export interface RequestFavoriteEventDataDto {
  isFavorite: boolean;
  eventId: string;
}

export interface UserDto {
  id: string;
  username?: string;
  enrollmentType?: UserEnrollmentTypeDto;
  email?: string;
  year?: string;
  score?: number;
  isBanned?: boolean;
  groupId?: string;
  authType?: UserAuthTypeDto;
  trackedEvents?: string[];
  favorites?: string[];
}

export interface UpdateUserDataDto {
  user: UserDto;
  deleted: boolean;
}

export interface AddManagerDto {
  email: string;
  organizationId: string;
}

export interface JoinOrganizationDto {
  accessCode: string;
}
