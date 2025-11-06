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
export interface CompletedChallengeDto {}

export enum ChallengeLocationDto {
  ENG_QUAD = 'ENG_QUAD',
  ARTS_QUAD = 'ARTS_QUAD',
  AG_QUAD = 'AG_QUAD',
  CENTRAL_CAMPUS = 'CENTRAL_CAMPUS',
  NORTH_CAMPUS = 'NORTH_CAMPUS',
  WEST_CAMPUS = 'WEST_CAMPUS',
  CORNELL_ATHLETICS = 'CORNELL_ATHLETICS',
  VET_SCHOOL = 'VET_SCHOOL',
  COLLEGETOWN = 'COLLEGETOWN',
  ITHACA_COMMONS = 'ITHACA_COMMONS',
  ANY = 'ANY',
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
