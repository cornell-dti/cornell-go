/** DTO for closeAccount */
export interface CloseAccountDto {}

/** DTO for setUsername */
export interface SetUsernameDto {
  newUsername: string;
}

/** DTO for setAuthToOAuth */
export interface SetAuthToOAuthDto {
  provider: "apple" | "google";
  authId: string;
}

/** DTO for setAuthToDevice */
export interface SetAuthToDeviceDto {
  deviceId: string;
}

/** DTO for requestGlobalLeaderData */
export interface RequestGlobalLeaderDataDto {
  offset: number;
  count: number;
}

/** DTO for requestUserData */
export interface RequestUserDataDto {
  userId?: string;
}

export type UserAuthTypeDto = "device" | "apple" | "google";

/** DTO for updateUserData event */
export interface UserDto {
  id: string;
  username: string;
  score: number;
  groupId: string;
  authType: UserAuthTypeDto;
  rewardIds?: string[];
  trackedEventIds?: string[];
}

export interface UpdateUserDto {
  user: UserDto | string;
  deleted: boolean;
}