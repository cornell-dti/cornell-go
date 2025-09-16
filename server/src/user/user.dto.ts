import { PrevChallenge } from '@prisma/client';

/** DTO for closeAccount */
export interface CloseAccountDto {}

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
  hasCompletedOnboarding?: boolean;
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
  enrollmentType?:
    | 'UNDERGRADUATE'
    | 'GRADUATE'
    | 'FACULTY'
    | 'ALUMNI'
    | 'GUEST';
  email?: string;
  year?: string;
  college?: string;
  major?: string;
  interests?: string[];
  score?: number;
  isBanned?: boolean;
  groupId?: string;
  authType?: UserAuthTypeDto;
  trackedEvents?: string[];
  favorites?: string[];
  hasCompletedOnboarding?: boolean;
}

export interface UpdateUserDataDto {
  user: UserDto;
  deleted: boolean;
}
export interface AddManagerDto {
  email: string;
  organizationId: string;
}

export interface JoinOrganizationDto {
  accessCode: string;
}
