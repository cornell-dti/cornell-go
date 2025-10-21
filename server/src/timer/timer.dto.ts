import { ChallengeDto } from "../challenge/challenge.dto";

/**
 * DTOs for Timer Lifecycle events: TimerStartedDto, TimerExtendedDto, TimerCompletedDto
 * DTOs for Timer Control Requests: ExtendTimerDto, StartChallengeTimerDto
 * DTOs for Warning Notifications: TimerWarningDto
 */
export interface TimerStartedDto {
    endTime: string;
    challengeId: string;
}
export interface TimerExtendedDto {
    challengeId: string;
    newEndTime: string;
}
export interface TimerCompletedDto {
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

