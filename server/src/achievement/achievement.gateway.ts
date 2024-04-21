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
  AchievementTrackerDto,
  RequestAchievementDataDto,
  UpdateAchievementDataDto,
} from './achievement.dto';
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
    private clientService: ClientService,
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
    const achs = await this.achievementService.getAchievementsByIdsForAbility(
      ability,
      data.achievements,
    );
    console.log(achs.length);
    for (const ach of achs) {
      await this.achievementService.emitUpdateAchievementData(ach, false, user);
    }
  }

  /**
   * Updates achievement data based on a provided DTO.
   * Triggered by the 'updateAchievementData' message.
   * @param ability
   * @param user
   * @param data
   * @returns
   */
  @SubscribeMessage('updateAchievementData')
  async updateAchievementData(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: UpdateAchievementDataDto,
  ) {
    // TODO: need to change organizations when removing achievement
    const achievement = await this.achievementService.getAchievementFromId(
      data.achievement.id,
    );

    if (data.deleted) {
      if (
        !achievement ||
        !(await this.achievementService.removeAchievement(
          ability,
          achievement.id,
        ))
      ) {
        await this.clientService.emitErrorData(user, 'Failed to delete event!');
        return;
      }
      await this.achievementService.emitUpdateAchievementData(
        achievement,
        true,
      );
    } else {
      const achievement =
        await this.achievementService.upsertAchievementFromDto(
          ability,
          data.achievement,
        );

      if (!achievement) {
        await this.clientService.emitErrorData(
          user,
          'Failed to upsert achievement!',
        );
        return;
      }

      this.clientService.subscribe(user, achievement.id);
      await this.achievementService.emitUpdateAchievementData(
        achievement,
        false,
      );
    }
  }
}
