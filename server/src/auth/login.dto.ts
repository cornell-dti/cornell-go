export interface LoginDto {
  idToken: string;
  lat: number;
  long: number;
  username?: string;
  year?: string;
  aud?: 'android' | 'ios' | 'web';
  enrollmentType: 'UNDERGRADUATE' | 'GRADUATE' | 'FACULTY' | 'ALUMNI';
}
