import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { User, AuthType } from '../model/user.entity';
import { JwtService } from '@nestjs/jwt';
import { UserService } from '../user/user.service';
import appleSignin from 'apple-signin-auth';
import { JwtPayload } from './jwt-payload';
import { LoginTicket, OAuth2Client } from 'google-auth-library';
import { pbkdf2, randomBytes } from 'crypto';
import { InjectRepository } from '@mikro-orm/nestjs';
import { EntityRepository } from '@mikro-orm/postgresql';
import { MikroORM } from '@mikro-orm/core';

interface IntermediatePayload {
  id: string;
  email: string;
}

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User) private userRepository: EntityRepository<User>,
    private readonly jwtService: JwtService,
    @Inject(forwardRef(() => UserService))
    private readonly userService: UserService,
  ) {}

  googleIosClient = new OAuth2Client(process.env.GOOGLE_IOS_CLIENT_ID);
  googleAndroidClient = new OAuth2Client(process.env.GOOGLE_ANDROID_CLIENT_ID);
  googleWebClient = new OAuth2Client(process.env.GOOGLE_WEB_CLIENT_ID);

  refreshOptions = {
    expiresIn: process.env.JWT_REFRESH_EXPIRATION,
    secret: process.env.JWT_REFRESH_SECRET,
  };

  accessOptions = {
    expiresIn: process.env.JWT_ACCESS_EXPIRATION,
    secret: process.env.JWT_ACCESS_SECRET,
  };

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
    aud: 'android' | 'ios' | 'web',
  ): Promise<IntermediatePayload | null> {
    try {
      let ticket: LoginTicket | null = null;
      if (aud === 'android') {
        ticket = await this.googleAndroidClient.verifyIdToken({
          idToken,
        });
      } else if (aud === 'ios') {
        ticket = await this.googleIosClient.verifyIdToken({
          idToken,
        });
      } else if (aud === 'web') {
        ticket = await this.googleWebClient.verifyIdToken({
          idToken,
        });
      }
      const payload = ticket?.getPayload();

      if (!payload) {
        console.log('Failed to verify with google');
        return null;
      }

      return { id: payload.sub, email: payload.email ?? '' };
    } catch (error) {
      console.log(error);
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
    aud?: 'ios' | 'android' | 'web',
  ): Promise<[string, string] | null> {
    // if verify success, idToken is a string. If anything is wrong, it is undefined
    let idToken: IntermediatePayload | null = null;
    switch (authType) {
      case AuthType.GOOGLE:
        if (!aud) {
          console.log('Google aud is missing');
          return null;
        }
        idToken = await this.payloadFromGoogle(token, aud);
        break;
      case AuthType.APPLE:
        idToken = await this.payloadFromApple(token);
        break;
      case AuthType.DEVICE:
        idToken = {
          id: token,
          email: 'dev@cornell.edu',
        };
        break;
    }

    if (!idToken || !idToken.email.endsWith('@cornell.edu')) {
      if (!idToken) {
        console.log('Id token was null!');
      } else {
        console.log('Non cornell account was used!');
      }
      return null;
    }

    let user = await this.userService.byAuth(authType, idToken.id);

    const isDevWhileDevice =
      process.env.DEVELOPMENT === 'true' || authType !== AuthType.DEVICE;

    if (!user && isDevWhileDevice) {
      user = await this.userService.register(
        idToken.email,
        idToken.email?.split('@')[0],
        lat,
        long,
        authType,
        idToken.id,
      );
    }
      
    if (!user) return null;
      
    user.adminRequested = !user.adminGranted && aud === 'web';

    const accessToken = await this.jwtService.signAsync(
      {
        userId: user.id,
      } as JwtPayload,
      this.accessOptions,
    );

    const refreshToken = await this.jwtService.signAsync(
      {
        userId: user.id,
      } as JwtPayload,
      this.refreshOptions,
    );

    user.hashedRefreshToken = await this.hashSalt(refreshToken);

    await this.userRepository.persistAndFlush(user);

    if (aud === 'web' && !user.adminGranted) return null;

    return [accessToken, refreshToken];
  }

  async refreshAccessToken(refreshToken: string): Promise<string | null> {
    try {
      const payload: JwtPayload = await this.jwtService.verifyAsync(
        refreshToken,
        this.refreshOptions,
      );

      const user = await this.userService.byId(payload.userId);

      if (
        !user ||
        !(await this.verifyHashSalt(refreshToken, user.hashedRefreshToken))
      )
        return null;

      const accessToken = await this.jwtService.signAsync(
        {
          userId: user.id,
        } as JwtPayload,
        this.accessOptions,
      );

      return accessToken;
    } catch {
      return null;
    }
  }

  /** Sets a user's authentication type based on token */
  async setAuthType(user: User, authType: AuthType, token: string) {
    user.authType = authType;
    user.authToken = token;

    await this.userRepository.persistAndFlush(user);
  }

  async userByToken(token: string): Promise<User | null> {
    try {
      const decodedPayload = await this.jwtService.verifyAsync<JwtPayload>(
        token,
        this.accessOptions,
      );
      return (await this.userService.byId(decodedPayload.userId)) ?? null;
    } catch (e) {
      console.log(e);
      return null;
    }
  }

  private async pdfk2Async(
    input: string,
    salt: string,
    iterations: number,
    length: number,
    digest: string,
  ) {
    return new Promise<Buffer>((resolve, reject) =>
      pbkdf2(input, salt, iterations, length, digest, (err, key) => {
        if (err) reject(err);
        else resolve(key);
      }),
    );
  }

  private async hashSalt(input: string): Promise<string> {
    const salt = randomBytes(128).toString('hex');
    const iterations = 10000;
    const hash = await this.pdfk2Async(input, salt, iterations, 64, 'sha512');
    return salt + hash.toString('hex');
  }

  private async verifyHashSalt(
    input: string,
    hashSalt: string,
  ): Promise<boolean> {
    const salt = hashSalt.substring(0, 256);
    const iterations = 10000;
    const hash = await this.pdfk2Async(input, salt, iterations, 64, 'sha512');

    return salt + hash.toString('hex') === hashSalt;
  }
}
