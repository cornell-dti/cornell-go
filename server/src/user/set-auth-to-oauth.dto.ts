/** DTO for setAuthToOAuth provider */
export type SetAuthToOAuthProviderDto = 'apple' | 'google';

/** DTO for setAuthToOAuth */
export interface SetAuthToOAuthDto {
  accessToken: string;
  provider: string;
  authId: string;
}
