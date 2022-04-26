import { RestrictionDto } from './request-restrictions.dto';

export interface UpdateRestrictionsDto {
  restrictions: RestrictionDto[];
  deletedIds: string[];
}
