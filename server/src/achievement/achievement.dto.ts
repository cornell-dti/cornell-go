import { ChallengeLocationDto } from '../challenge/challenge.dto';

export enum AchievementTypeDto {
  TOTAL_POINTS = 'TOTAL_POINTS',
  TOTAL_CHALLENGES = 'TOTAL_CHALLENGES',
  TOTAL_JOURNEYS = 'TOTAL_JOURNEYS',
  TOTAL_CHALLENGES_OR_JOURNEYS = 'TOTAL_CHALLENGES_OR_JOURNEYS',
}

export interface AchievementDto {
  id: string;
  eventId?: string;
  requiredPoints?: number;
  name?: string;
  description?: string;
  imageUrl?: string;
  locationType?: ChallengeLocationDto;
  achievementType?: AchievementTypeDto;
  initialOrganizationId?: string;
}

export interface AchievementTrackerDto {
  userId: string;
  progress: number;
  achievementId: string;
  dateComplete?: string;
}

export interface UpdateAchievementDataDto {
  achievement: AchievementDto;
  deleted: boolean;
}
/** DTO for requestAchievementData */
export interface RequestAchievementDataDto {
  achievements: string[];
}

export interface RequestAchievementTrackerDataDto {
  achievements?: string[];
}
