/** DTO for group member in updateGroupData */
export interface UpdateGroupDataMemberDto {
  id: string;
  name: string;
  points: number;
  host: boolean;
  curChallengeId: string;
}

/** DTO for updateGroupData */
export interface UpdateGroupDataDto {
  curEventId: string;
  members: UpdateGroupDataMemberDto[];
  removeListedMembers: boolean;
}
