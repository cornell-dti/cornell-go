import { UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { User } from '@prisma/client';
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { UpdateRewardDataDto } from '../client/update-reward-data.dto';
import { RequestRewardDataDto } from './request-reward-data.dto';
import { RewardService } from './reward.service';

@WebSocketGateway({ cors: true })
@UseGuards(UserGuard)
export class RewardGateway {
  constructor(
    private clientService: ClientService,
    private rewardService: RewardService,
  ) {}

  @SubscribeMessage('requestRewardData')
  async requestRewardData(
    @CallingUser() user: User,
    @MessageBody() data: RequestRewardDataDto,
  ) {
    const rewardData = await this.rewardService.getRewardsForUser(
      user,
      data.rewardIds,
    );

    const rewardDataUnowned = await this.rewardService.getRewardsNotForUser(
      user,
      data.rewardIds,
    );

    const updateData: UpdateRewardDataDto = {
      rewards: [
        ...rewardData.map(rw => ({
          rewardId: rw.id,
          eventId: rw.eventId,
          description: rw.description,
          redeemInfo: rw.redeemInfo,
          isRedeemed: rw.isRedeemed,
        })),
        ...rewardDataUnowned.map(rw => ({
          rewardId: rw.id,
          eventId: rw.eventId,
          description: rw.description,
          redeemInfo: '',
          isRedeemed: false,
        })),
      ],
    };

    this.clientService.emitUpdateRewardData(user, updateData);
    return false;
  }
}
