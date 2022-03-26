import { UseGuards } from '@nestjs/common';
import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { UserGuard } from 'src/auth/jwt-auth.guard';
import { CallingUser } from '../auth/calling-user.decorator';
import { ClientService } from '../client/client.service';
import { UpdateRewardDataDto } from '../client/update-reward-data.dto';
import { User } from '../model/user.entity';
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

    const updateData: UpdateRewardDataDto = {
      rewards: rewardData.map(rw => ({
        eventId: rw.containingEvent.id,
        description: rw.rewardDescription,
        redeemInfo: rw.rewardRedeemInfo,
        isRedeemed: rw.isRedeemed,
      })),
    };

    this.clientService.emitUpdateRewardData(user, updateData);
    return false;
  }
}
