import { MikroOrmModule } from '@mikro-orm/nestjs';
import { forwardRef, Module } from '@nestjs/common';
import { AuthModule } from 'src/auth/auth.module';
import { ClientModule } from 'src/client/client.module';
import { EventModule } from 'src/event/event.module';
import { EventReward } from 'src/model/event-reward.entity';
import { RewardModule } from 'src/reward/reward.module';
import { GroupModule } from '../group/group.module';
import { Challenge } from '../model/challenge.entity';
import { PrevChallenge } from '../model/prev-challenge.entity';
import { UserModule } from '../user/user.module';
import { ChallengeGateway } from './challenge.gateway';
import { ChallengeService } from './challenge.service';

@Module({
  imports: [
    MikroOrmModule.forFeature([Challenge, PrevChallenge, EventReward]),
    forwardRef(() => EventModule),
    GroupModule,
    UserModule,
    RewardModule,
    ClientModule,
    AuthModule,
  ],
  providers: [ChallengeGateway, ChallengeService],
})
export class ChallengeModule {}
