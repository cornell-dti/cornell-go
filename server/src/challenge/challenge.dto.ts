/** DTO for completedChallenge */
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
  containingEventId?: string;
}

/** DTO for requestChallengeData */
export interface RequestChallengeDataDto {
  challenges: string[];
}

export interface UpdateChallengeDataDto {
  challenge: ChallengeDto;
  deleted: boolean;
}

/** DTO for requestEventTrackerData */
export interface RequestEventTrackerDataDto {
  trackedEvents: string[];
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
