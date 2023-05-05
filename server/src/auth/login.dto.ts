export interface LoginDto {
  idToken: string;
  lat: number;
  long: number;
  username?: string;
  year?: string;
  aud?: 'android' | 'ios' | 'web';
  userStatus:
    | 'Undergraduate Student'
    | 'Graduate Student'
    | 'Faculty/Staff'
    | 'Alumni';
}
