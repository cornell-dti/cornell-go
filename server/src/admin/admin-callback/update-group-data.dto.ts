import { GroupDto } from '../update-groups.dto';

export interface UpdateGroupDataDto {
  groups: GroupDto[];
  deletedIds: string[];
}
