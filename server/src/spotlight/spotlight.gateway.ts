import { UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { User } from '@prisma/client';
import { UserGuard } from '../auth/jwt-auth.guard';
import { CallingUser } from '../auth/calling-user.decorator';
import { SpotlightService } from './spotlight.service';
import {
  SpotlightDto,
  ActiveSpotlightDto,
  RequestSpotlightNotificationDto,
  SpotlightNotificationResultDto,
  DeleteSpotlightDto,
} from './spotlight.dto';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class SpotlightGateway {
  constructor(private readonly spotlightService: SpotlightService) {}

  @SubscribeMessage('getActiveSpotlights')
  async getActiveSpotlights(): Promise<ActiveSpotlightDto[]> {
    return this.spotlightService.getActiveSpotlights();
  }

  @SubscribeMessage('requestSpotlightNotification')
  async requestSpotlightNotification(
    @CallingUser() user: User,
    @MessageBody() data: RequestSpotlightNotificationDto,
  ): Promise<SpotlightNotificationResultDto> {
    return this.spotlightService.requestNotification(
      user.id,
      data.spotlightId,
      data.latitude,
      data.longitude,
    );
  }

  @SubscribeMessage('getAllSpotlights')
  async getAllSpotlights(
    @CallingUser() user: User,
  ): Promise<SpotlightDto[] | null> {
    if (!user.administrator) {
      return null;
    }
    return this.spotlightService.getAllSpotlights();
  }

  @SubscribeMessage('createSpotlight')
  async createSpotlight(
    @CallingUser() user: User,
    @MessageBody() data: Omit<SpotlightDto, 'id'>,
  ): Promise<SpotlightDto | null> {
    if (!user.administrator) {
      return null;
    }
    return this.spotlightService.createSpotlight(data);
  }

  @SubscribeMessage('updateSpotlight')
  async updateSpotlight(
    @CallingUser() user: User,
    @MessageBody() data: SpotlightDto,
  ): Promise<SpotlightDto | null> {
    if (!user.administrator) {
      return null;
    }
    return this.spotlightService.updateSpotlight(data);
  }

  @SubscribeMessage('deleteSpotlight')
  async deleteSpotlight(
    @CallingUser() user: User,
    @MessageBody() data: DeleteSpotlightDto,
  ): Promise<boolean> {
    if (!user.administrator) {
      return false;
    }
    return this.spotlightService.deleteSpotlight(data.id);
  }
}
