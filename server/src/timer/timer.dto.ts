/**
 * DTOs for Timer Lifecycle events: TimerStartedDto, TimerExtendedDto, TimerCompletedDto
 * DTOs for Timer Control Requests: ExtendTimerDto, StartChallengeTimerDto
 * DTOs for Warning Notifications: TimerWarningDto
 */
export interface TimerStartedDto {
  timerId: string;
  endTime: string;
  challengeId: string;
  extensionsUsed: number;
}
export interface TimerExtendedDto {
  timerId: string;
  challengeId: string;
  newEndTime: string;
  extensionsUsed: number;
}
export interface TimerCompletedDto {
  timerId: string;
  challengeId: string;
  challengeCompleted: boolean; // true if completed, false if failed
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
  milestone: number; // milestone (300s passed, 60s passed, 30s passed)
  timeRemaining: number; // seconds remaining
}

export interface ChallengeFailedDto {
  challengeId: string;
  userId: string;
}
