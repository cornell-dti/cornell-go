export interface RestrictionDto {
  id: string;
  displayName: string;
  canEditUsername: boolean;
  restrictedUsers: string[];
  allowedEvents: string[];
  generatedUserCount: number;
  generatedUserAuthIds: string[];
}

export interface RequestRestrictionsDto {}
