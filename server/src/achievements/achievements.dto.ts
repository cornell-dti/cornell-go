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
  requiredPoints: number;
  name: string;
  description: string;
  imageUrl: string;
  event?: boolean;
  locationType: LocationType;
  achievementType: AchievementType;
  associatedOrganizations: string[]; 
}

export interface AchievementTrackerDto {
  associatedUser: string; 
  progress: number;
  associatedAchievement: AchievementDto; 
  dateComplete?: Date;
}