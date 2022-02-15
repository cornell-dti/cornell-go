import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, AuthType } from '../model/user.entity';
import { JwtService } from '@nestjs/jwt';
import {
  auth,
  LoginTicket,
  OAuth2Client,
  TokenPayload,
} from 'google-auth-library';
import { AuthConstants } from './constant';
import { UserService } from '../user/user.service';
import appleSignin from 'apple-signin-auth';
@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User) private userRepository: Repository<User>,
    private readonly jwtService: JwtService,
    @Inject(forwardRef(() => UserService))
    private readonly UserService: UserService,
  ) {}

  /** Get identifier from an apple token */
  async getIdFromAppleToken(token: string): Promise<string | undefined> {
    const verifiedToken = await this.verifyApple(token);
    if (!verifiedToken) {
      return undefined;
    }
    return verifiedToken;
  }

  async verifyApple(token_id: string): Promise<string | undefined> {
    try {
      const { sub: userAppleId } = await appleSignin.verifyIdToken(
        token_id, // We need to pass the token that we wish to decode.
        {
          audience: AuthConstants.client_id, // client id - The same one we used  on the frontend, this is the secret key used for encoding and decoding the token.
          ignoreExpiration: true, // Token will not expire unless you manually do so.
        },
      );
      return userAppleId;
    } catch (err) {
      // if any error pops up during the verifying stage, the process terminate
      // and return the error to the front end
      return undefined;
    }
  }

  /** Get identifier from a google token */
  async getIdFromGoogleToken(token: string): Promise<string | undefined> {
    const verifiedToken = await this.verifyGoogle(token);
    if (!verifiedToken) {
      return undefined;
    }
    return verifiedToken;
  }

  async verifyGoogle(token_id: string): Promise<string | undefined> {
    try {
      const client = new OAuth2Client(AuthConstants.client_id);
      const ticket: LoginTicket = await client.verifyIdToken({
        idToken: token_id,
        audience: AuthConstants.client_id,
      });
      const payload = ticket.getPayload();
      if (!payload) {
        return undefined;
      }
      const authToken: string = payload['sub'];
      return authToken;
    } catch (error) {
      // if any error pops up during the verifying stage, the process terminate
      // and return the error to the front end
      return undefined;
    }
  }

  async login(id_token: string, authenType: AuthType): Promise<string> {
    // if verify success, idToken is a string. If anything is wrong, it is undefined
    let idToken: string | undefined;
    switch (authenType) {
      case AuthType.GOOGLE:
        idToken = await this.getIdFromGoogleToken(id_token);
        break;
      case AuthType.APPLE:
        idToken = await this.getIdFromAppleToken(id_token);
        break;
      case AuthType.DEVICE:
        //idToken = this.getIdFromDeviceToken(id_token);
        break;
    }
    if (!idToken) {
      return 'verify error';
    }
    this.registerUser(authenType, idToken);
    return 'login success';
  }

  async registerUser(authType: AuthType, authToken: string) {
    const exist_user: User | undefined = await this.userRepository.findOne({
      authType,
      authToken,
    });
    if (exist_user) {
      const payload: object = {
        username: exist_user.username,
        sub: exist_user.id,
      };
      //TODO:
      // return {
      //   access_token: this.jwtService.sign(payload),
      // };
    }
    // this would go wrong if the user does not let google share its information
    //https://developers.google.com/identity/sign-in/web/backend-auth#create-an-account-or-session
    else {
      // if we do not have this user in our database, we register
      // const email: string = payload['email'];
      // const username: string = payload['name'];
      // const lat: number = 0;
      // const long: number = 0;
      // const user = await this.UserService.register(
      //   email,
      //   username,
      //   lat,
      //   long,
      //   authType,
      //   authToken,
      // );
      // const payload_token: object = { username: user.username, sub: user.id };
      // return {
      //   access_token: this.jwtService.sign(payload_token),
      // };
    }
    return '';
  }

  /** Get identifier from a device token */
  getIdFromDeviceToken(token: string): string | undefined {
    return token;
  }

  /** Sets a user's authentication type based on token */
  async setAuthType(user: User, authType: AuthType, token: string) {
    let idToken: string | undefined = '';

    switch (authType) {
      case AuthType.APPLE:
        idToken = await this.getIdFromAppleToken(token);
        break;
      case AuthType.DEVICE:
        idToken = this.getIdFromDeviceToken(token);
        break;
      case AuthType.GOOGLE:
        idToken = await this.getIdFromGoogleToken(token);
        break;
    }

    if (!idToken) return false;

    user.authType = authType;
    user.authToken = idToken;

    this.userRepository.save(user);

    return true;
  }
}
