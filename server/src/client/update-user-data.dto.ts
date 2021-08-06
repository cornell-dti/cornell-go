/** DTO for updateUserData auth type */
export type UpdateUserDataAuthTypeDto = 'device' | 'apple' | 'google';

/** DTO for updateUserData event */
export interface UpdateUserDataDto {
  id: string;
  username: string;
  score: number;
  groupId: string;
  rewardIds: string[];
  trackedEventIds: string[];
  ignoreIdLists: boolean;
  authType: UpdateUserDataAuthTypeDto;
}
