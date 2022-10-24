import { forwardRef, Module } from '@nestjs/common';
import { AuthModule } from 'src/auth/auth.module';
import { ClientModule } from 'src/client/client.module';
import { EventModule } from 'src/event/event.module';
import { RewardModule } from 'src/reward/reward.module';
import { GroupModule } from '../group/group.module';
import { PrismaModule } from '../prisma/prisma.module';
import { UserModule } from '../user/user.module';
import { ChallengeGateway } from './challenge.gateway';
import { ChallengeService } from './challenge.service';

@Module({
  imports: [
    forwardRef(() => EventModule),
    GroupModule,
    UserModule,
    RewardModule,
    ClientModule,
    AuthModule,
    PrismaModule,
  ],
  providers: [ChallengeGateway, ChallengeService],
})
export class ChallengeModule {}
