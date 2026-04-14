import { Body, Controller, Headers, Post } from '@nestjs/common';
import { AuthService } from '../auth/auth.service';
import { SpotlightService } from './spotlight.service';
import {
  RequestSpotlightNotificationDto,
  SpotlightNotificationResultDto,
} from './spotlight.dto';

@Controller('spotlight')
export class SpotlightController {
  constructor(
    private readonly spotlightService: SpotlightService,
    private readonly authService: AuthService,
  ) {}

  /* Called by the Flutter app when the user enters a spotlight zone
  
  HTTP instead of websockets because background geofence callbacks run on a seperate instance than 
  what CGO uses for socket conncetion. 

  */
  @Post('notify')
  async requestNotification(
    @Headers('authorization') authHeader: string,
    @Body() dto: RequestSpotlightNotificationDto,
  ): Promise<SpotlightNotificationResultDto> {
    const token = authHeader?.replace('Bearer ', '');
    if (!token) {
      return { sent: false, reason: 'Missing authorization token' };
    }

    const user = await this.authService.userByToken(token);
    if (!user) {
      return { sent: false, reason: 'Invalid token' };
    }

    return this.spotlightService.requestNotification(
      user.id,
      dto.spotlightId,
      dto.latitude,
      dto.longitude,
    );
  }
}
