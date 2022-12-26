import { UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { User } from '@prisma/client';
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { EventService } from 'src/event/event.service';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import {
  RequestRewardDataDto,
  RewardDto,
  UpdateRewardDataDto,
} from './reward.dto';
import { RewardService } from './reward.service';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class RewardGateway {
  constructor(
    private clientService: ClientService,
    private rewardService: RewardService,
    private eventService: EventService,
  ) {}

  @SubscribeMessage('requestRewardData')
  async requestRewardData(
    @CallingUser() user: User,
    @MessageBody() data: RequestRewardDataDto,
  ) {
    const owned = await this.rewardService.getRewardsForUser(
      user,
      data.rewardIds,
    );

    const unowned = await this.rewardService.getRewardsNotForUser(
      user,
      data.rewardIds,
    );

    for (const rw of owned) {
      await this.rewardService.emitUpdateRewardData(rw, false, true, user);
    }

    for (const rw of unowned) {
      await this.rewardService.emitUpdateRewardData(rw, false, false, user);
    }
  }

  @SubscribeMessage('updateRewardData')
  async updateRewardData(
    @CallingUser() user: User,
    @MessageBody() data: UpdateRewardDataDto,
  ) {
    if (data.deleted) {
      const rw = await this.rewardService.getRewardById(data.reward as string);
      const ev = await this.eventService.getEventById(rw.eventId);

      if (
        !(await this.eventService.hasAdminRights(
          {
            id: rw.eventId,
          },
          user,
        ))
      ) {
        return;
      }

      await this.rewardService.removeReward(rw.id, user);
      await this.rewardService.emitUpdateRewardData(rw, true);
      await this.eventService.emitUpdateEventData(ev, false);
    } else {
      const dto = data.reward as RewardDto;

      if (
        !(await this.eventService.hasAdminRights(
          {
            id: dto.eventId,
          },
          user,
        ))
      ) {
        return;
      }

      const rw = await this.rewardService.upsertRewardFromDto(dto);
      const ev = await this.eventService.getEventById(rw.eventId);

      await this.rewardService.emitUpdateRewardData(rw, false);
      await this.eventService.emitUpdateEventData(ev, false);
    }
  }
}
