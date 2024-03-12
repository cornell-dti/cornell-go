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

export interface BanUserDto {
  userId: string;
  isBanned: boolean;
}
/** DTO for setAuthToOAuth */
export interface SetAuthToOAuthDto {
  provider: 'apple' | 'google';
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

/** DTO for requestFavoriteEventData */
export interface RequestFavoriteEventDataDto {
  isFavorite: boolean;
  eventId: string;
}

export type UserAuthTypeDto = 'device' | 'apple' | 'google';

/** DTO for updateUserData event */
export interface UserDto {
  id: string;
  username?: string;
  enrollmentType?: 'UNDERGRADUATE' | 'GRADUATE' | 'FACULTY' | 'ALUMNI';
  email?: string;
  year?: string;
  score?: number;
  isBanned?: boolean;
  groupId?: string;
  authType?: UserAuthTypeDto;
  trackedEvents?: string[];
  favorites?: string[];
}

export interface UpdateUserDataDto {
  user: UserDto;
  deleted: boolean;
}

export type eventFilterDto = 'new' | 'saved' | 'finished';

export interface RequestFilteredEventDto {
  filter: eventFilterDto;
  cursorId?: string;
  limit: number;
}
