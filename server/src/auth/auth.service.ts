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

/**
 * `AuthService` - Handles authentication and user session management.
 *
 * @remarks
 * This service is responsible for user authentication using Google, Apple, and device-based sign-in.
 * It verifies ID tokens, registers new users if needed, and issues JWT access and refresh tokens.
 * It also provides functionalities for token-based user retrieval, access token refreshing, and
 * checking user management roles.
 *
 * The authentication process supports multiple platforms (`web`, `android`, `ios`) using platform-specific
 * Google OAuth clients. Apple authentication is verified through Apple Sign-In ID tokens.
 *
 * The service integrates with `UserService` for user retrieval and registration and uses `PrismaService`
 * for database interactions. It also utilizes JWT for secure token generation and verification.
 *
 * @param prisma - Injected `PrismaService` for database operations.
 * @param jwtService - Injected `JwtService` for handling JWT authentication.
 * @param userService - Injected `UserService` to manage user-related operations.
 *
 * @returns Provides authentication-related functionalities, including:
 * - Verifying Google and Apple ID tokens.
 * - Handling user login and registration.
 * - Issuing and refreshing JWT tokens.
 * - Retrieving users by authentication tokens.
 * - Checking if a user manages any organizations.
 */
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

  /**
   * Verifies an Apple ID token and extracts the user's ID and email.
   *
   * @param idToken - The ID token from Apple Sign-In.
   * @returns An object containing the user’s `id` and `email` if verification is successful;
   *          otherwise, `null` if verification fails.
   */
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

  /**
   * Verifies a Google ID token based on the audience (platform) and extracts the user's ID and email.
   *
   * @param idToken - The ID token received from Google.
   * @param aud - The platform that issued the token: 'android', 'ios', or 'web'.
   * @returns An object containing the user's `id` and `email` if verification is successful;
   *          otherwise, `null` if verification fails.
   */
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

  /**
   * Authenticates a user based on the user credentials, issues access and refresh tokens.
   *
   * @param authType - The type of authentication used.
   * @param req - The login DTO containing user credentials.
   * @returns A tuple `[accessToken, refreshToken]` if login is successful;
   *          otherwise, `null` if authentication fails.
   */
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

    if (!user && !req.noRegister) {
      user = await this.userService.register(
        idToken.email,
        req.username,
        req.year ?? '2000',
        req.college ?? '',
        req.major ?? '',
        req.interests?.split(',') ?? [],
        req.latF ?? 0,
        req.longF ?? 0,
        authType,
        idToken.id,
        req.enrollmentType,
      );

      if (!user) {
        console.log('Unable to register user');
        return null;
      }
    }

    // if user is null here, then it means we're not registering this user now (req.noRegister === true)
    if (!user) {
      return null;
    }

    if (user.isBanned) return null;

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

  async getManagedOrgs(user: User) {
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
