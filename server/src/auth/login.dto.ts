export interface LoginDto {
  idToken: string;
  lat: number;
  long: number;
  aud?: 'android' | 'ios' | 'web';
}
