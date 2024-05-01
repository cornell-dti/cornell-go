export interface OrganizationDto {
  id: string;
  name?: string;
  accessCode?: string;
  members?: string[];
  events?: string[];
  managers?: string[];
  achivements?: string[];
}

export interface RequestOrganizationDataDto {
  admin: boolean;
}

export interface UpdateOrganizationDataDto {
  organization: OrganizationDto;
  deleted: boolean;
}
