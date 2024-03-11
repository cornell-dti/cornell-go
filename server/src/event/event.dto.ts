/** DTO for requestEventData */
export interface RequestEventDataDto {
  eventIds: string[];
}

/** DTO for requestEventLeaderData */
export interface RequestEventLeaderDataDto {
  offset: number;
  count: number;
  eventId: string;
}

export type TimeLimitationDto = 'LIMITED_TIME' | 'PERPETUAL';

export type EventDifficultyDto = 'EASY' | 'NORMAL' | 'HARD';

export type EventLocationDto =
  | 'ENG_QUAD'
  | 'ARTS_QUAD'
  | 'AG_QUAD'
  | 'NORTH_CAMPUS'
  | 'WEST_CAMPUS'
  | 'COLLEGETOWN'
  | 'ITHACA_COMMONS'
  | 'OTHER';

export type EventCategoryDto =
  | 'FOOD'
  | 'NATURE'
  | 'HISTORICAL'
  | 'CAFE'
  | 'DININGHALL'
  | 'DORM';

export interface EventDto {
  id: string;
  requiredMembers: number;
  name: string;
  description: string;
  timeLimitation: TimeLimitationDto;
  endTime: string;
  challengeIds: string[];
  userFavoriteIds?: string[];
  initialOrganizationId?: string;
  difficulty: EventDifficultyDto;
  category: EventCategoryDto;
  location: EventLocationDto;
  indexable: boolean;
}

/** DTO for event tracker in updateEventTrackerData */
export interface EventTrackerDto {
  eventId: string;
  isRanked: boolean;
  curChallengeId: string;
  prevChallengeIds: string[];
  prevChallengeDates: string[];
}

/** DTO for updateEventTrackerData */
export interface UpdateEventTrackerDataDto {
  tracker: EventTrackerDto;
}

export interface UpdateEventDataDto {
  event: EventDto | string;
  deleted: boolean;
}

/** DTO for searchEvents */
export interface SearchEventsDto {
  searchId: string;
  offset: number;
  count: number;
  locations?: EventLocationDto[];
  difficulties?: EventDifficultyDto[];
  categories?: EventCategoryDto[];
}

export interface EventSearchResultsDto {
  searchId: string;
  offset: number;
  count: number;
  eventIds: string[];
}
