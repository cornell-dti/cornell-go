import { Controller, Post, Body } from '@nestjs/common';
import { AuthType } from '@prisma/client';
import { AuthService } from '../auth.service';
import { LoginDto } from '../login.dto';

@Controller('device-login')
export class DeviceLoginController {
  constructor(private readonly authService: AuthService) {}

  // login
  @Post()
  async login(
    @Body() req: LoginDto,
  ): Promise<{ accessToken: string; refreshToken: string } | null> {
    const tokens = await this.authService.login(
      req.idToken,
      AuthType.DEVICE,
      req.lat,
      req.long,
    );

    return tokens && { accessToken: tokens[0], refreshToken: tokens[1] };
  }
}
