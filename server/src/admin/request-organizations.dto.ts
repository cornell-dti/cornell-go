export interface OrganizationDto {
  id: string;
  displayName: string;
  isDefault: boolean;
  canEditUsername: boolean;
  members: string[];
  allowedEvents: string[];
  // generatedUserCount: number;
  // generatedUserAuthIds: string[];
}

export interface RequestOrganizationsDto {}
