import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AuthType, User } from '@prisma/client';
import appleSignin from 'apple-signin-auth';
import { pbkdf2, randomBytes } from 'crypto';
import { LoginTicket, OAuth2Client } from 'google-auth-library';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from '../user/user.service';
import { JwtPayload } from './jwt-payload';
import { LoginDto } from './login.dto';

interface IntermediatePayload {
  id: string;
  email: string;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
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
    authType: AuthType,
    req: LoginDto,
  ): Promise<[string, string] | null> {
    
    // if verify success, idToken is a string. If anything is wrong, it is undefined
    let idToken: IntermediatePayload | null = null;
    switch (authType) {
      case AuthType.GOOGLE:
        if (!req.aud) {
          console.log('Google aud is missing');
          return null;
        }
        idToken = await this.payloadFromGoogle(req.idToken, req.aud);
        break;
      case AuthType.APPLE:
        idToken = await this.payloadFromApple(req.idToken);
        break;
      case AuthType.DEVICE:
        idToken = {
          id: req.idToken,
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
    if (!user && req.username && req.year) {
      user = await this.userService.register(
        idToken.email,
        req.username,
        req.year,
        req.lat,
        req.long,
        authType,
        idToken.id,
        req.userStatus
      );
    }

    if (!user) return null;

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
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        hashedRefreshToken: await this.hashSalt(refreshToken),
      },
    });

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

  async getManagedOrgIds(user: User) {
    return (
      await this.prisma.organization.findMany({
        where: { managers: { some: { id: user.id } } },
        select: { id: true },
      })
    ).map(({ id }) => id);
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
