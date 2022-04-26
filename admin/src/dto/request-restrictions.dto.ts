export interface RestrictionDto {
  id: string;
  displayName: string;
  canEditUsername: boolean;
  restrictedUsers: string[];
  allowedEvents: string[];
  generatedUserCount: number;
}

export interface RequestRestrictionsDto {}
