import {
  CanActivate,
  ExecutionContext,
  Inject,
  Injectable,
} from '@nestjs/common';
/*
    Custom imports for AuthService, jwt secret, etc...
*/
import { Socket } from 'socket.io';
import { Handshake } from 'socket.io/dist/socket';
import { AuthService } from './auth.service';

export function tokenOfHandshake(handshake: Handshake) {
  return (
    (handshake.auth['token'] as string | undefined) ??
    (process.env.DEVELOPMENT !== 'false' &&
      (handshake.query['token'] as string))
  );
}

@Injectable()
export class UserGuard implements CanActivate {
  constructor(@Inject(AuthService) private authService: AuthService) {}

  async canActivate(context: ExecutionContext) {
    const client = context.switchToWs().getClient<Socket>();
    const token = tokenOfHandshake(client.handshake);

    if (!token) return false;

    const user = await this.authService.userByToken(token);
    if (user) {
      context.switchToWs().getData()._authenticatedUserEntity = user;
    } else {
      return false;
    }

    return true;
  }
}
