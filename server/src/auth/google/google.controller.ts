import { Controller, Post, Req } from '@nestjs/common';
import { AuthService } from '../auth.service';
import { Request } from 'express';

@Controller('google')
export class GoogleController {
  constructor(private readonly authService: AuthService) {}

  // login
  @Post('/auth/login')
  async login(@Req() req: Request) {
    return this.authService.loginGoogle(req.token);
  }
}
