import { forwardRef, Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ClientModule } from '../client/client.module';
import { EventModule } from '../event/event.module';
import { PrismaModule } from '../prisma/prisma.module';
import { RewardGateway } from './reward.gateway';
import { RewardService } from './reward.service';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    ClientModule,
    EventModule,
    PrismaModule,
  ],
  exports: [RewardService],
  providers: [RewardGateway, RewardService],
})
export class RewardModule {}
