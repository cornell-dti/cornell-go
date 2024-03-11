/** DTO for searchEvents */
export interface SearchEventsDto {
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
  // thumbnail: string; // should be of type Image
  description: string;
  timeLimitation: "LIMITED_TIME" | "PERPETUAL";
  endTime: string;
  challengeIds: string[];
  userFavoriteIds?: string[];
  initialOrganizationId?: string;
  difficulty: "EASY" | "Normal" | "Hard";
  indexable: boolean;
  latitude: number;
  longitude: number;
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
