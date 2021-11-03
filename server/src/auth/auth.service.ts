import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, AuthType } from '../model/user.entity';
import { JwtService } from '@nestjs/jwt';
import { OAuth2Client } from 'google-auth-library';
import { AuthConstants } from './constant';
import { UserService } from '../user/user.service'

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User) private userRepository: Repository<User>,
    private readonly jwtService: JwtService,
    private readonly UserService: UserService
  ) {}

  /** Get identifier from an apple token */
  getIdFromAppleToken(token: string): string | undefined {
    return undefined;
  }

  /** Get identifier from a google token */
  getIdFromGoogleToken(token: string): string | undefined {

    return undefined
  }

  
  async verifyGoogle(token_id : string): Promise<any> {
    try {
      const client = new OAuth2Client(AuthConstants.client_id);
      const ticket: any = await client.verifyIdToken({
        idToken: token_id,
        audience: AuthConstants.client_id, 
      });
      const payload = ticket.getPayload();
      //const userid = payload['sub'];
      return payload
    }
    catch(error) {
      if (error) {
        return "error"
      }
    }
    return "error"
  }


  async loginGoogle(ID_token : string) {
    const payload = await this.verifyGoogle(ID_token);
    const authType: AuthType = AuthType.GOOGLE;
    const authToken: string = payload['sub'];
    const exist_user: User | undefined = await this.userRepository.findOne({ authType, authToken });
    if (exist_user) {
      const payload : object = { username: exist_user.username, sub: exist_user.id };
      return {
        access_token: this.jwtService.sign(payload),
      }
    }
// this would go wrong if the user does not let google share its information
//https://developers.google.com/identity/sign-in/web/backend-auth#create-an-account-or-session
    else {
      const email: string = payload['email']
      const username : string = payload['name']
      const lat : number  =  0
      const long : number = 0
      const user = await this.UserService.register(email, username, lat, long, authType, authToken)
      const payload_token : object = { username: user.username, sub: user.id };
      return {
        access_token: this.jwtService.sign(payload_token),
      }
    }

    

  }
  /** Get identifier from a device token */
  getIdFromDeviceToken(token: string): string | undefined {
    return token;
  }

  async validateUser(username: string, password: string) {
    return true;
  }

  /** Sets a user's authentication type based on token */
  async setAuthType(user: User, authType: AuthType, token: string) {
    let idToken: string | undefined = '';

    switch (authType) {
      case AuthType.APPLE:
        idToken = this.getIdFromAppleToken(token);
        break;
      case AuthType.DEVICE:
        idToken = this.getIdFromDeviceToken(token);
        break;
      case AuthType.GOOGLE:
        idToken = this.getIdFromGoogleToken(token);
        break;
    }

    if (!idToken) return false;

    user.authType = authType;
    user.authToken = idToken;

    this.userRepository.save(user);

    return true;
  }
}
