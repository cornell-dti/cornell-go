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
import { AchievementDto, AchievementTrackerDto, RequestAchievementDataDto, UpdateAchievementDataDto } from './achievement.dto';
import { AchievementService } from './achievement.service';
import { PoliciesGuard } from '../casl/policy.guard';
import { UserAbility } from '../casl/user-ability.decorator';
import { AppAbility } from '../casl/casl-ability.factory';
import { Action } from '../casl/action.enum';
import { subject } from '@casl/ability';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard, PoliciesGuard)
export class AchievementGateway {
  constructor(
    private achievementService: AchievementService,
    private clientService: ClientService
  ) {}

  /** 
   * request achievements by list of ids
   * update achievement with a dto
   * @param user
   * @param data
   */

  @SubscribeMessage('requestAchievementData')
  async requestAchievementData(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: RequestAchievementDataDto,
  ) {
    const achievement = 
    await this.achievementService.getAchievementsByIdsForAbility(ability, data.achievements);
  }


  @SubscribeMessage('updateAchievementData')
  async updateAchievementData(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: UpdateAchievementDataDto,
  ) {
    const achievement = await this.achievementService.getAchievementFromId(data.achievement.id);

    if (!achievement && ability.cannot(Action.Create, 'Achievement')) {
      await this.clientService.emitErrorData(
        user,
        'Permission denied for achievement update!',
      );
      return;
    }

    if (data.deleted && achievement) {
      await this.achievementService.removeAchievement(ability, achievement.id);
      await this.achievementService.emitUpdateAchievementData(achievement, true);
    } else {
      const achievement = await this.achievementService.upsertAchievementFromDto(ability, data.achievement);
    }

    if (!achievement) {
      await this.clientService.emitErrorData(user, 'Failed to update achievement!');
      return;
    }
  }
}

