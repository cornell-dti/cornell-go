import { Module } from '@nestjs/common';
import { RewardGateway } from './reward.gateway';

@Module({
  providers: [RewardGateway]
})
export class RewardModule {}
