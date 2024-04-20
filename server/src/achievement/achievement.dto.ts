import { ChallengeLocationDto } from '../challenge/challenge.dto';

export enum AchievementTypeDto {
  TotalPoints = 'TOTAL_POINTS',
  TotalChallenges = 'TOTAL_CHALLENGES',
  TotalJourneys = 'TOTAL_JOURNEYS',
  TotalChallengesOrJourneys = 'TOTAL_CHALLENGES_OR_JOURNEYS',
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

export interface RequestAchievementDataDto {
  achievements: string[];
}
