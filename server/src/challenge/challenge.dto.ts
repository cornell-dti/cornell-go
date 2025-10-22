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

/**
 * DTOs for Timer Lifecycle events: TimerStartedDto, TimerExtendedDto, TimerCompletedDto
 * DTOs for Timer Control Requests: ExtendTimerDto, StartChallengeTimerDto
 * DTOs for Warning Notifications: TimerWarningDto
 */
export interface TimerStartedDto {
  timerId: string;
  endTime: string;
  challengeId: string;
}
export interface TimerExtendedDto {
  timerId: string;
  challengeId: string;
  newEndTime: string;
}
export interface TimerCompletedDto {
  timerId: string;
  challengeId: string;
  challengeCompleted: boolean; //true if completed, false if failed 
}

export interface ExtendTimerDto {
  challengeId: string;
  endTime: string;
}

export interface StartChallengeTimerDto {
  challengeId: string;
}

export interface TimerWarningDto {
  challengeId: string;
  milestone: number; //milestone (300s passed, 60s passed, 30s passed)
  timeRemaining: number; //seconds remaining
}
