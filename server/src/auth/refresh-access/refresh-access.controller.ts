import { Body, Controller, Post, Res } from '@nestjs/common';
import { AuthService } from '../auth.service';
import { RefreshTokenDto } from '../refreshToken.dto';

@Controller('refresh-access')
export class RefreshAccessController {
  constructor(private authService: AuthService) {}

  @Post()
  async refresh(
    @Body() tokenDto: RefreshTokenDto,
  ): Promise<{ accessToken: string } | null> {
    const accessToken = await this.authService.refreshAccessToken(
      tokenDto.refreshToken,
    );
    return accessToken ? { accessToken } : null;
  }
}
