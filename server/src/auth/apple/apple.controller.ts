import { Controller, Post, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from '../auth.service';

@Controller('apple')
export class AppleController {
  
  constructor(private readonly authService: AuthService) {}

  // login
  // @UseGuards(AuthGuard('local'))
  // @Post('/auth/login')
  // async login(@Request() req) {
  //   return this.authService.login(req.user);
  // }

}

