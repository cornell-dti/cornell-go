export enum LocationType {
  EngQuad = 'ENG_QUAD',
  ArtsQuad = 'ARTS_QUAD',
  AgQuad = 'AG_QUAD',
  NorthCampus = 'NORTH_CAMPUS',
  WestCampus = 'WEST_CAMPUS',
  Collegetown = 'COLLEGETOWN',
  IthacaCommons = 'ITHACA_COMMONS',
  Any = 'OTHER',
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
  locationType: LocationType;
  achievementType: AchievementType;
  organizationIds: string[];
}

export interface AchievementTrackerDto {
  userId: string;
  progress: number;
  achievementId: string;
  dateComplete?: string;
}
