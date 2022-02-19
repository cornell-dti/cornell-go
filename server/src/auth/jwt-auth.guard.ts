import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
/*
    Custom imports for AuthService, jwt secret, etc...
*/
import { Socket } from 'socket.io';
import { AuthService } from './auth.service';

@Injectable()
export class UserGuard implements CanActivate {
  constructor(private authService: AuthService) {}

  async canActivate(context: ExecutionContext) {
    const client = context.switchToWs().getClient<Socket>();
    const token = client.handshake.auth['token'];

    const user = await this.authService.userByToken(token);
    if (user) {
      context.switchToWs().getData()._authenticatedUserEntity = user;
    } else {
      return false;
    }

    return true;
  }
}

@Injectable()
export class AdminGuard implements CanActivate {
  constructor(private authService: AuthService) {}

  async canActivate(context: ExecutionContext) {
    const client = context.switchToWs().getClient<Socket>();
    const token = client.handshake.auth['token'];

    const user = await this.authService.userByToken(token);
    if (user && user.adminGranted) {
      context.switchToWs().getData()._authenticatedUserEntity = user;
    } else {
      return false;
    }

    return true;
  }
}
