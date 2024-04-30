/** DTO for completedChallenge */
export interface CompletedChallengeDto {
  challengeId: string;
}

export enum ChallengeLocationDto {
  ENG_QUAD = 'ENG_QUAD',
  ARTS_QUAD = 'ARTS_QUAD',
  AG_QUAD = 'AG_QUAD',
  NORTH_CAMPUS = 'NORTH_CAMPUS',
  WEST_CAMPUS = 'WEST_CAMPUS',
  COLLEGETOWN = 'COLLEGETOWN',
  ITHACA_COMMONS = 'ITHACA_COMMONS',
  ANY = 'ANY',
}

export interface ChallengeDto {
  id: string;
  name?: string;
  location?: ChallengeLocationDto;
  description?: string;
  points?: number;
  imageUrl?: string;
  latF?: number;
  longF?: number;
  awardingRadiusF?: number;
  closeRadiusF?: number;
  linkedEventId?: string;
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
