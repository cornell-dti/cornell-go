/**
 * LoginDto defines a user's login status and stores a user's basic information
 * such as idToken, lat, long, username, year, aud, and enrollmentType.
 */
export interface LoginDto {
  idToken: string;
  noRegister: boolean;
  latF?: number;
  longF?: number;
  username?: string;
  year?: string;
  college?: string;
  major?: string;
  interests?: string;
  aud?: 'android' | 'ios' | 'web';
  enrollmentType: 'UNDERGRADUATE' | 'GRADUATE' | 'FACULTY' | 'ALUMNI' | 'GUEST';
}
