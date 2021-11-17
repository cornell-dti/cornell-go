import { Controller, Post, Body } from '@nestjs/common';
import { AuthType } from 'src/model/user.entity';
import { AuthService } from '../auth.service';
import { TokenDto } from '../constant';

@Controller('google')
export class GoogleController {
  constructor(private readonly authService: AuthService) {}

  // login
  @Post()
  async login(@Body() req: TokenDto) {
    const success: string = await this.authService.login(
      req.token,
      AuthType.GOOGLE,
    );
    // success is a string, either"login success" or "verify error"
    return success;
  }
}
