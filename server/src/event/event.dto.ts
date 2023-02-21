/** DTO for requestAllEventData */
export interface RequestAllEventDataDto {
  offset: number;
  count: number;
}

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

export interface EventDto {
  id: string;
  requiredMembers: number;
  name: string;
  description: string;
  rewardType: 'limited_time' | 'perpetual';
  endTime: string;
  rewardIds: string[];
  challengeIds: string[];
  userFavoriteIds?: string[];
  initialOrganizationId?: string;
  defaultChallengeId: string;
  minimumScore: number;
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
