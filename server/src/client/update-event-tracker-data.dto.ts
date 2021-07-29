/** DTO for event tracker in updateEventTrackerData */
export interface UpdateEventTrackerDataEventTrackerDto {
  eventId: string;
  isRanked: boolean;
  cooldownMinimum: string;
  curChallengeId: boolean;
  prevChallengeIds: string[];
}

/** DTO for updateEventTrackerData */
export interface UpdateEventTrackerDataDto {
  eventTrackers: UpdateEventTrackerDataEventTrackerDto[];
}
