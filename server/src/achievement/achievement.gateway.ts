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
import { AchievementDto, AchievementTrackerDto } from './achievement.dto';
import { AchievementService } from './achievement.service';
import { PoliciesGuard } from '../casl/policy.guard';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard, PoliciesGuard)
export class AchievementGateway {
  constructor(private achievementService: AchievementService) {}
}
