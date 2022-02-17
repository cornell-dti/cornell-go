import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, AuthType } from '../model/user.entity';
import { JwtService } from '@nestjs/jwt';
import { UserService } from '../user/user.service';
import appleSignin from 'apple-signin-auth';
import { JwtPayload } from './jwt-payload';
import { LoginTicket, OAuth2Client } from 'google-auth-library';
import crypto from 'crypto';

interface IntermediatePayload {
  id: string;
  email: string;
}

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User) private userRepository: Repository<User>,
    private readonly jwtService: JwtService,
    @Inject(forwardRef(() => UserService))
    private readonly userService: UserService,
  ) {}
  googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

  async payloadFromApple(idToken: string): Promise<IntermediatePayload | null> {
    try {
      const payload = await appleSignin.verifyIdToken(
        idToken, // We need to pass the token that we wish to decode.
        {
          audience: process.env.APPLE_CLIENT_ID, // client id - The same one we used  on the frontend, this is the secret key used for encoding and decoding the token.
          ignoreExpiration: true, // Token will not expire unless you manually do so.
        },
      );
      return { id: payload.sub, email: payload.email };
    } catch (err) {
      // if any error pops up during the verifying stage, the process terminate
      // and return the error to the front end
      return null;
    }
  }

  async payloadFromGoogle(
    idToken: string,
  ): Promise<IntermediatePayload | null> {
    try {
      const ticket: LoginTicket = await this.googleClient.verifyIdToken({
        idToken,
      });
      const payload = ticket.getPayload();

      if (!payload) {
        return null;
      }

      return { id: payload.sub, email: payload.email ?? '' };
    } catch (error) {
      // if any error pops up during the verifying stage, the process terminate
      // and return the error to the front end
      return null;
    }
  }

  async login(
    token: string,
    authType: AuthType,
    lat: number,
    long: number,
  ): Promise<[string, string] | null> {
    // if verify success, idToken is a string. If anything is wrong, it is undefined
    let idToken: IntermediatePayload | null = null;
    switch (authType) {
      case AuthType.GOOGLE:
        idToken = await this.payloadFromGoogle(token);
        break;
      case AuthType.APPLE:
        idToken = await this.payloadFromApple(token);
        break;
      case AuthType.DEVICE:
        idToken = { id: token, email: '' };
        break;
    }

    if (!idToken) return null;

    let user = await this.userService.byAuth(authType, idToken.id);

    if (!user) {
      user = await this.userService.register(
        idToken.email,
        idToken.email?.split('@')[0],
        lat,
        long,
        authType,
        idToken.id,
      );
    }

    const accessToken = await this.jwtService.signAsync({
      userId: user.id,
    } as JwtPayload);

    const refreshToken = await this.jwtService.signAsync(
      {
        userId: user.id,
      } as JwtPayload,
      {
        expiresIn: process.env.JWT_REFRESH_EXPIRATION,
        secret: process.env.JWT_REFRESH_SECRET,
      },
    );

    user.hashedRefreshToken = crypto
      .createHash('sha512')
      .update(refreshToken)
      .digest('hex');

    await this.userRepository.save(user);

    return [accessToken, refreshToken];
  }

  async refreshAccessToken(refreshToken: string): Promise<string | null> {
    try {
      const payload: JwtPayload = await this.jwtService.verifyAsync(
        refreshToken,
        {
          secret: process.env.JWT_REFRESH_SECRET,
        },
      );

      const hashedRefreshToken = crypto
        .createHash('sha512')
        .update(refreshToken)
        .digest('hex');

      const user = await this.userService.byId(payload.userId);

      if (hashedRefreshToken !== user?.hashedRefreshToken) return null;

      const accessToken = await this.jwtService.signAsync({
        userId: user.id,
      } as JwtPayload);

      return accessToken;
    } catch {
      return null;
    }
  }

  /** Sets a user's authentication type based on token */
  async setAuthType(user: User, authType: AuthType, token: string) {
    user.authType = authType;
    user.authToken = token;

    this.userRepository.save(user);
  }

  async userByToken(token: string): Promise<User | null> {
    try {
      const decodedPayload = await this.jwtService.verifyAsync<JwtPayload>(
        token,
      );
      return (await this.userService.byId(decodedPayload.userId)) ?? null;
    } catch {
      return null;
    }
  }
}
