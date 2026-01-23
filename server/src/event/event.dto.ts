/** DTO for filtering events based on multiple criteria
 * Used in requestFilteredEvents (clients to request events matching specific filters)
 */
export interface RequestFilteredEventsDto {
  difficulty: string[];
  location: string[];
  category: string[];
  filterId: string[];
}

/** DTO for requesting event data by IDs
 * Used in requestEventData (fetch specific events or all events if no IDs provided)
 */
export interface RequestEventDataDto {
  events?: string[];
}

/** DTO for requesting event leaderbaord data
 * Used for pagination and specific event leaderboard retrieval
 */
export interface RequestEventLeaderDataDto {
  offset: number;
  count: number;
  eventId?: string;
}

/** DTO for representing a user entry on the leaderboard
 * Contains minimal user data needed for leaderboard display
 */
export interface LeaderDto {
  userId: string;
  username: string;
  score: number;
}

/** DTO for updating leaderboard data
 * Used to send leaderboard updates to clients
 */
export interface UpdateLeaderDataDto {
  eventId?: string;
  offset: number;
  users: LeaderDto[];
}

/**
 * DTO for updating a single player's position on leaderboard
 * Used when a player's score changes
 */
export interface UpdateLeaderPositionDto {
  playerId: string;
  newTotalScore: number;
  newEventScore: number;
  eventId: string;
}

/**
 * DTO for requesting events near a geographic location
 * Used for location-based recommendations
 */
export interface RequestRecommendedEventsDto {
  latitudeF: number;
  longitudeF: number;
  count?: number;
}

/**
 * Enum defining possible event categories
 * Used for categorization and filtering of events
 */
export enum EventCategoryDto {
  FOOD = 'FOOD',
  NATURE = 'NATURE',
  HISTORICAL = 'HISTORICAL',
  CAFE = 'CAFE',
  DININGHALL = 'DININGHALL',
  DORM = 'DORM',
}

/**
 * Primary DTO for event data
 * Contains all properties needed to display and interact with an event
 */
export interface EventDto {
  id: string;
  requiredMembers?: number;
  name?: string;
  description?: string;
  longDescription?: string;
  category?: EventCategoryDto;
  timeLimitation?: 'LIMITED_TIME' | 'PERPETUAL';
  endTime?: string;
  challenges?: string[];
  userFavorites?: string[];
  initialOrganizationId?: string;
  difficulty?: 'Easy' | 'Normal' | 'Hard';
  indexable?: boolean;
  longitudeF?: number;
  latitudeF?: number;
}

/** DTO for PrevChallenge as used in EventTrackerDto */
export interface PrevChallengeDto {
  challengeId: string;
  hintsUsed: number;
  extensionsUsed?: number;
  dateCompleted: string;
  failed?: boolean; // True if challenge was failed due to timer expiration
}

/** DTO for event tracker in updateEventTrackerData */
export interface EventTrackerDto {
  eventId: string;
  isRanked: boolean;
  hintsUsed: number;
  curChallengeId?: string;
  prevChallenges: PrevChallengeDto[];
}

/** DTO for updateEventTrackerData */
export interface UpdateEventTrackerDataDto {
  tracker: EventTrackerDto;
}

/**
 * DTO for updating event data
 * Used when event details change or an event is deleted
 */
export interface UpdateEventDataDto {
  event: EventDto;
  deleted: boolean;
}

export interface UseEventTrackerHintDto {}
