import { Controller, Post, Request } from '@nestjs/common';
import { AuthService } from '../auth.service';

@Controller('google')
export class GoogleController {
  constructor(private readonly authService: AuthService) {}

  // login
  @Post('/auth/login')
  async login(@Request() req) {
    return this.authService.loginGoogle(req.token);
  }

}
