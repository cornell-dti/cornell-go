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
  RequestAchievementTrackerDataDto,
  UpdateAchievementDataDto,
} from './achievement.dto';
import { AchievementService } from './achievement.service';
import { PoliciesGuard } from '../casl/policy.guard';
import { UserAbility } from '../casl/user-ability.decorator';
import { AppAbility } from '../casl/casl-ability.factory';
import { Action } from '../casl/action.enum';
import { subject } from '@casl/ability';
import { OrganizationService } from '../organization/organization.service';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard, PoliciesGuard)
export class AchievementGateway {
  constructor(
    private achievementService: AchievementService,
    private clientService: ClientService,
    private orgService: OrganizationService,
  ) {}

  /**
   * request achievements by list of ids
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

    for (const ach of achs) {
      await this.achievementService.emitUpdateAchievementData(ach, false, user);
    }

    return achs.length;
  }

  /**
   * request achievement trackers by list of ids
   * @param user
   * @param data
   */

  @SubscribeMessage('requestAchievementTrackerData')
  async requestAchievementTrackerData(
    @UserAbility() ability: AppAbility,
    @CallingUser() user: User,
    @MessageBody() data: RequestAchievementTrackerDataDto,
  ) {
    const achs = await this.achievementService.getAchievementTrackersForUser(
      user,
      data.achievements,
    );

    for (const ach of achs) {
      await this.achievementService.emitUpdateAchievementTracker(ach, user);
    }

    return achs.length;
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

      const org = await this.orgService.getOrganizationById(
        data.achievement.initialOrganizationId!,
      );

      if (org) {
        await this.orgService.emitUpdateOrganizationData(org, false);
      }

      this.clientService.subscribe(user, achievement.id);
      await this.achievementService.emitUpdateAchievementData(
        achievement,
        false,
      );
    }

    return achievement?.id;
  }
}
