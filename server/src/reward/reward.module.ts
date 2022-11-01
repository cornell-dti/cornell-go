import { forwardRef, Module } from '@nestjs/common';
import { AuthModule } from 'src/auth/auth.module';
import { ClientModule } from 'src/client/client.module';
import { PrismaModule } from '../prisma/prisma.module';
import { RewardGateway } from './reward.gateway';
import { RewardService } from './reward.service';

@Module({
  imports: [forwardRef(() => AuthModule), ClientModule, PrismaModule],
  providers: [RewardGateway, RewardService],
})
export class RewardModule {}
