/**
 * LoginDto defines a user's login status and stores a user's basic information
 * such as idToken, lat, long, username, year, aud, and enrollmentType.
 */
export interface LoginDto {
  idToken: string;
  lat: number;
  long: number;
  username?: string;
  year?: string;
  aud?: 'android' | 'ios' | 'web';
  enrollmentType: 'UNDERGRADUATE' | 'GRADUATE' | 'FACULTY' | 'ALUMNI';
}
