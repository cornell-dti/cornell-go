import { Body, Controller, Post, Res } from '@nestjs/common';
import { Response } from 'express';
import { AuthService } from '../auth.service';
import { RefreshTokenDto } from '../refreshToken.dto';

@Controller('refresh-access')
export class RefreshAccessController {
  constructor(private authService: AuthService) {}

  @Post()
  async refresh(@Body() tokenDto: RefreshTokenDto): Promise<string | null> {
    return await this.authService.refreshAccessToken(tokenDto.refreshToken);
  }
}
