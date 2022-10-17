import { Module } from '@nestjs/common';
import { AuthModule } from 'src/auth/auth.module';
import { ClientModule } from 'src/client/client.module';
import { RewardGateway } from './reward.gateway';
import { RewardService } from './reward.service';

@Module({
  imports: [ClientModule, AuthModule],
  providers: [RewardGateway, RewardService],
})
export class RewardModule {}
