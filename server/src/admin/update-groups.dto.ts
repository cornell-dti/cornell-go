export interface GroupDto {
  id: string;
  friendlyId: string;
  hostId: string;
  curEventId: string;
}

export interface UpdateGroupsDto {
  groups: GroupDto[];
  deletedIds: string[];
}
