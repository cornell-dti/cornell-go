/** DTO for requestAllEventData */
export interface RequestAllEventDataDto {
  offset: number;
  count: number;
}

/** DTO for requestEventData */
export interface RequestEventDataDto {
  events?: string[];
}

/** DTO for requestEventLeaderData */
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

export enum EventCategoryDto {
  FOOD = 'FOOD',
  NATURE = 'NATURE',
  HISTORICAL = 'HISTORICAL',
  CAFE = 'CAFE',
  DININGHALL = 'DININGHALL',
  DORM = 'DORM',
}

export interface EventDto {
  id: string;
  requiredMembers?: number;
  name?: string;
  description?: string;
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
  dateCompleted: string;
}

/** DTO for event tracker in updateEventTrackerData */
export interface EventTrackerDto {
  eventId: string;
  isRanked: boolean;
  hintsUsed: number;
  curChallengeId: string;
  prevChallenges: PrevChallengeDto[];
}

/** DTO for updateEventTrackerData */
export interface UpdateEventTrackerDataDto {
  tracker: EventTrackerDto;
}

export interface UpdateEventDataDto {
  event: EventDto;
  deleted: boolean;
}

export interface UseEventTrackerHintDto {}