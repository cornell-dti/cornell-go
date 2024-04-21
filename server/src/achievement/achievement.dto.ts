export enum AchievementLocationType {
  EngQuad = 'ENG_QUAD',
  ArtsQuad = 'ARTS_QUAD',
  AgQuad = 'AG_QUAD',
  NorthCampus = 'NORTH_CAMPUS',
  WestCampus = 'WEST_CAMPUS',
  Collegetown = 'COLLEGETOWN',
  IthacaCommons = 'ITHACA_COMMONS',
  Any = 'ANY',
}

export enum AchievementType {
  TotalPoints = 'TOTAL_POINTS',
  TotalChallenges = 'TOTAL_CHALLENGES',
  TotalJourneys = 'TOTAL_JOURNEYS',
  TotalChallengesOrJourneys = 'TOTAL_CHALLENGES_OR_JOURNEYS',
}

export interface AchievementDto {
  id: string;
  eventId: string;
  requiredPoints: number;
  name: string;
  description: string;
  imageUrl: string;
  locationType: AchievementLocationType;
  achievementType: AchievementType;
  organizations: string[];
}

export interface AchievementTrackerDto {
  userId: string;
  progress: number;
  achievementId: string;
  dateComplete?: string;
}
