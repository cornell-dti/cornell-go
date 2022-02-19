import { MikroOrmModule } from '@mikro-orm/nestjs';
import { Module } from '@nestjs/common';
import { ClientModule } from 'src/client/client.module';
import { EventReward } from 'src/model/event-reward.entity';
import { RewardGateway } from './reward.gateway';
import { RewardService } from './reward.service';

@Module({
  imports: [MikroOrmModule.forFeature([EventReward]), ClientModule],
  providers: [RewardGateway, RewardService],
})
export class RewardModule {}
