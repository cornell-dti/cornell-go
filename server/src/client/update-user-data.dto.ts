/** DTO for updateUserData event */
export interface UpdateUserDataDto {
  id: string;
  username: string;
  score: number;
  groupId: string;
  rewardIds: string[];
  trackedEventIds: string[];
}
