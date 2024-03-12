/** DTO for requestAllEventData */
export interface RequestAllEventDataDto {
  offset: number;
  count: number;
}

/** DTO for requestEventData */
export interface RequestEventDataDto {
  events: string[];
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
  challenges: string[];
  userFavorites?: string[];
  initialOrganizationId?: string;
  difficulty: "Easy" | "Normal" | "Hard";
  indexable: boolean;
  latitude: number;
  longitude: number;
}

/** DTO for event tracker in updateEventTrackerData */
export interface EventTrackerDto {
  eventId: string;
  isRanked: boolean;
  curChallengeId: string;
  prevChallenges: string[];
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
