export enum LocationType {
  EngQuad = 'EngQuad',
  ArtsQuad = 'ArtsQuad',
  AgQuad = 'AgQuad',
  NorthCampus = 'NorthCampus',
  WestCampus = 'WestCampus',
  Collegetown = 'Collegetown',
  IthacaCommons = 'IthacaCommons',
  Any = 'Any',
}

export enum AchievementType {
  TotalPoints = 'TotalPoints',
  TotalChallenges = 'TotalChallenges',
  TotalJourneys = 'TotalJourneys',
  TotalChallengesOrJourneys = 'TotalChallengesOrJourneys',
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
