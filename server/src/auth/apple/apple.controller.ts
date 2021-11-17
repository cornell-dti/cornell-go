import { Controller, Post, Body } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthType } from 'src/model/user.entity';
import { AuthService } from '../auth.service';
import { TokenDto } from '../constant';

@Controller('apple')
export class AppleController {
  constructor(private readonly authService: AuthService) {}

  @Post()
  async login(@Body() req: TokenDto) {
    const success: string = await this.authService.login(
      req.token,
      AuthType.APPLE,
    );
    // success is a string, either"login success" or "verify error"
    return success;
  }
}

/**Useful sources:
 * https://dev.to/heyitsarpit/how-to-add-signin-with-apple-on-your-website-43m9 */
