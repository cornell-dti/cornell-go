import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientModule } from 'src/client/client.module';
import { EventReward } from 'src/model/event-reward.entity';
import { RewardGateway } from './reward.gateway';
import { RewardService } from './reward.service';

@Module({
  imports: [TypeOrmModule.forFeature([EventReward]), ClientModule],
  providers: [RewardGateway, RewardService],
})
export class RewardModule {}
