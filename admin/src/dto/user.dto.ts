/** DTO for closeAccount */
export interface CloseAccountDto {}

/** DTO for setUsername */
export interface SetUsernameDto {
  newUsername: string;
}

/** DTO for setMajor */
export interface SetMajorDto {
  newMajor: string;
}

/** DTO for setGraduationYear */
export interface SetGraduationYearDto {
  newYear: string;
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

export interface RequestAllUserDataDto {}

export type UserAuthTypeDto = "device" | "apple" | "google";

/** DTO for updateUserData event */
export interface UserDto {
  id: string;
  username: string;
  major: string;
  year: string;
  score: number;
  groupId: string;
  authType: UserAuthTypeDto;
  trackedEventIds?: string[];
  favoriteIds?: string[];
}

export interface UpdateUserDataDto {
  user: UserDto | string;
  deleted: boolean;
}
