import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, AuthType } from '../model/user.entity';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User) private userRepository: Repository<User>,
  ) {}

  /** Get identifier from an apple token */
  getIdFromAppleToken(token: string): string | undefined {
    return undefined;
  }

  /** Get identifier from a google token */
  getIdFromGoogleToken(token: string): string | undefined {
    return undefined;
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
