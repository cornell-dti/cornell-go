import { SessionLogModule } from './../session-log/session-log.module';
import { forwardRef, Module } from '@nestjs/common';
import { ClientModule } from '../client/client.module';
import { EventModule } from '../event/event.module';
import { RewardModule } from '../reward/reward.module';
import { AuthModule } from '../auth/auth.module';
import { GroupModule } from '../group/group.module';
import { PrismaModule } from '../prisma/prisma.module';
import { UserModule } from '../user/user.module';
import { ChallengeGateway } from './challenge.gateway';
import { ChallengeService } from './challenge.service';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    EventModule,
    GroupModule,
    UserModule,
    RewardModule,
    ClientModule,
    PrismaModule,
    SessionLogModule,
  ],
  providers: [ChallengeGateway, ChallengeService],
})
export class ChallengeModule {}
