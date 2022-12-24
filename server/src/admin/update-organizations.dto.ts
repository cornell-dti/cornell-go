import { OrganizationDto } from './request-organizations.dto';

export interface UpdateOrganizationsDto {
  organizations: OrganizationDto[];
  deletedIds: string[];
}
