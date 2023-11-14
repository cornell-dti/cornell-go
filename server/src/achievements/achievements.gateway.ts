import { UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { User } from '@prisma/client';
import { UserGuard } from '../auth/jwt-auth.guard';
import { EventService } from '../event/event.service';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import {
  AchievementDto,
  AchievementTrackerDto
} from './achievements.dto';
import { AchievementService } from './achievements.service';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class AchievementGateway {
  constructor(
    private achievementService: AchievementService,
  ) {}
}
