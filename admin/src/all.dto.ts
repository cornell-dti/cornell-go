// CODE AUTOGENERATED BY npm run updateapi
// IF YOU MODIFY THIS FILE, MAKE SURE TO ALSO MODIFY THE updateapi SCRIPT!
// OTHERWISE YOUR CHANGES MAY BE OVERWRITTEN!
export enum AchievementTypeDto {
  TOTAL_POINTS = "TOTAL_POINTS",
  TOTAL_CHALLENGES = "TOTAL_CHALLENGES",
  TOTAL_JOURNEYS = "TOTAL_JOURNEYS",
  TOTAL_CHALLENGES_OR_JOURNEYS = "TOTAL_CHALLENGES_OR_JOURNEYS",
}

export enum LoginAudDto {
  android = "android",
  ios = "ios",
  web = "web",
}

export enum LoginEnrollmentTypeDto {
  UNDERGRADUATE = "UNDERGRADUATE",
  GRADUATE = "GRADUATE",
  FACULTY = "FACULTY",
  ALUMNI = "ALUMNI",
  GUEST = "GUEST",
}

export enum ChallengeLocationDto {
  ENG_QUAD = "ENG_QUAD",
  ARTS_QUAD = "ARTS_QUAD",
  AG_QUAD = "AG_QUAD",
  NORTH_CAMPUS = "NORTH_CAMPUS",
  WEST_CAMPUS = "WEST_CAMPUS",
  COLLEGETOWN = "COLLEGETOWN",
  ITHACA_COMMONS = "ITHACA_COMMONS",
  ANY = "ANY",
}

export enum EventCategoryDto {
  FOOD = "FOOD",
  NATURE = "NATURE",
  HISTORICAL = "HISTORICAL",
  CAFE = "CAFE",
  DININGHALL = "DININGHALL",
  DORM = "DORM",
}

export enum EventTimeLimitationDto {
  LIMITED_TIME = "LIMITED_TIME",
  PERPETUAL = "PERPETUAL",
}

export enum EventDifficultyDto {
  Easy = "Easy",
  Normal = "Normal",
  Hard = "Hard",
}

export enum SetAuthToOAuthProviderDto {
  apple = "apple",
  google = "google",
}

export enum UserEnrollmentTypeDto {
  UNDERGRADUATE = "UNDERGRADUATE",
  GRADUATE = "GRADUATE",
  FACULTY = "FACULTY",
  ALUMNI = "ALUMNI",
  GUEST = "GUEST",
}

export enum UserAuthTypeDto {
  apple = "apple",
  google = "google",
  device = "device",
}

export interface AchievementDto {
  id: string;
  eventId?: string;
  requiredPoints?: number;
  name?: string;
  description?: string;
  imageUrl?: string;
  locationType?: ChallengeLocationDto;
  achievementType?: AchievementTypeDto;
  initialOrganizationId?: string;
}

export interface AchievementTrackerDto {
  userId: string;
  progress: number;
  achievementId: string;
  dateComplete?: string;
}

export interface UpdateAchievementDataDto {
  achievement: AchievementDto;
  deleted: boolean;
}

export interface RequestAchievementDataDto {
  achievements: string[];
}

export interface LoginDto {
  idToken: string;
  lat: number;
  long: number;
  username?: string;
  year?: string;
  college?: string;
  major?: string;
  interests?: string;
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
  location?: ChallengeLocationDto;
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
  category?: EventCategoryDto;
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

export interface PrevChallengeDto {
  challengeId: string;
  hintsUsed: number;
  dateCompleted: string;
}

export interface EventTrackerDto {
  eventId: string;
  isRanked: boolean;
  hintsUsed: number;
  curChallengeId: string;
  prevChallenges: PrevChallengeDto[];
}

export interface UpdateEventTrackerDataDto {
  tracker: EventTrackerDto;
}

export interface UpdateEventDataDto {
  event: EventDto;
  deleted: boolean;
}

export interface UseEventTrackerHintDto {}

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

export interface SetCollegeDto {
  newCollege: string;
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
  college?: string;
  major?: string;
  interests?: string[];
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
