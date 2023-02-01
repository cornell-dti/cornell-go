/** DTO for joinGroup */
export interface JoinGroupDto {
  groupId: string;
}

/** DTO for leaveGroup */
export interface LeaveGroupDto {}

/** DTO for requestGroupData */
export interface RequestGroupDataDto {}

/** DTO for setCurrentEvent */
export interface SetCurrentEventDto {
  eventId: string;
}

/** DTO for group member in updateGroupData */
export interface GroupMemberDto {
  id: string;
  name: string;
  points: number;
  curChallengeId: string;
}

export interface GroupDto {
  id: string;
  friendlyId: string;
  hostId: string;
  curEventId: string;
  members: GroupMemberDto[];
}

export interface RequestGroupDataDto {}

export interface UpdateGroupDataDto {
  group: GroupDto | string;
  deleted: boolean;
}
