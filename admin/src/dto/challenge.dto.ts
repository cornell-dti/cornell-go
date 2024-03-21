/** DTO for completedChallenge */
export interface CompletedChallengeDto {
  challengeId: string;
}

export interface ChallengeDto {
  id: string;
  name: string;
  description: string;
  imageUrl: string;
  points: number;
  lat: number;
  long: number;
  awardingRadius: number;
  closeRadius: number;
  containingEventId: string;
}

/** DTO for requestChallengeData */
export interface RequestChallengeDataDto {
  challengeIds: string[];
}

export interface UpdateChallengeDataDto {
  challenge: ChallengeDto | string;
  deleted: boolean;
}

/** DTO for requestEventTrackerData */
export interface RequestEventTrackerDataDto {
  trackedEventIds: string[];
}

/** DTO for setCurrentChallenge */
export interface SetCurrentChallengeDto {
  challengeId: string;
}

/** DTO for user in updateLeaderData */
export interface LeaderDto {
  userId: string;
  username: string;
  score: number;
}

/** DTO for updateLeaderData */
export interface UpdateLeaderDataDto {
  eventId: string;
  offset: number;
  users: LeaderDto[];
}
