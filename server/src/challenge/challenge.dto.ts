export enum LocationType {
  EngQuad = 'ENG_QUAD',
  ArtsQuad = 'ARTS_QUAD',
  AgQuad = 'AG_QUAD',
  NorthCampus = 'NORTH_CAMPUS',
  WestCampus = 'WEST_CAMPUS',
  Collegetown = 'COLLEGETOWN',
  IthacaCommons = 'ITHACA_COMMONS',
  Any = 'Any',
}

/** DTO for completedChallenge */
export interface CompletedChallengeDto {
  challengeId: string;
}

export interface ChallengeDto {
  id: string;
  name: string;
  location: LocationType;
  description: string;
  points: number;
  imageUrl: string;
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
