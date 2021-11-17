import { Module } from '@nestjs/common';
import { RewardGateway } from './reward.gateway';
import { RewardService } from './reward.service';

@Module({
  providers: [RewardGateway, RewardService],
})
export class RewardModule {}
