import { SessionLogModule } from './../session-log/session-log.module';
import { forwardRef, Module } from '@nestjs/common';
import { ClientModule } from '../client/client.module';
import { EventModule } from '../event/event.module';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { UserModule } from '../user/user.module';
import { GroupModule } from '../group/group.module';
import { ChallengeGateway } from './challenge.gateway';
import { ChallengeService } from './challenge.service';
import { AchievementModule } from '../achievement/achievement.module';
import { CaslModule } from '../casl/casl.module';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    EventModule,
    UserModule,
    GroupModule,
    ClientModule,
    PrismaModule,
    SessionLogModule,
    CaslModule,
    AchievementModule,
  ],
  providers: [ChallengeGateway, ChallengeService],
})
export class ChallengeModule {}
