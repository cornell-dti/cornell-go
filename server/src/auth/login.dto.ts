export interface LoginDto {
  idToken: string;
  lat: number;
  long: number;
  username?: string;
  major?: string;
  year?: string;
  aud?: 'android' | 'ios' | 'web';
}
