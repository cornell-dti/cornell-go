import { Controller, Post, Body, Get, Query } from '@nestjs/common';
import { AuthType } from '@prisma/client';
import { AuthService } from '../auth.service';
import { LoginDto } from '../login.dto';
import { UserService } from '../../user/user.service';

@Controller('apple')
export class AppleController {
  constructor(
    private readonly authService: AuthService,
    private readonly userService: UserService,
  ) {}

  // login
  @Post()
  async login(
    @Body() req: LoginDto,
  ): Promise<{ accessToken: string; refreshToken: string } | null> {
    const tokens = await this.authService.login(AuthType.APPLE, req);

    return tokens && { accessToken: tokens[0], refreshToken: tokens[1] };
  }

  // check user existence
  @Get('check-user')
  async checkUser(
    @Query('idToken') idToken: string,
  ): Promise<{ exists: boolean; user?: any }> {
    const idTokenPayload = await this.authService.payloadFromApple(idToken);

    if (!idTokenPayload) {
      console.log('Invalid Apple token or unable to decode token');
      return { exists: false };
    }

    const user = await this.userService.byAuth(
      AuthType.APPLE,
      idTokenPayload.id,
    );
    return user ? { exists: true, user } : { exists: false };
  }
}
