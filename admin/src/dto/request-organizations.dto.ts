export interface OrganizationDto {
  id: string;
  displayName: string;
  canEditUsername: boolean;
  isDefault: boolean;
  members: string[];
  allowedEvents: string[];
  // generatedUserCount: number;
  // generatedUserAuthIds: string[];
}

export interface RequestOrganizationsDto {}
