import { MikroOrmModule } from '@mikro-orm/nestjs';
import { forwardRef, Module } from '@nestjs/common';
import { ClientModule } from 'src/client/client.module';
import { EventModule } from 'src/event/event.module';
import { RewardModule } from 'src/reward/reward.module';
import { Challenge } from '../model/challenge.entity';
import { PrevChallenge } from '../model/prev-challenge.entity';
import { UserModule } from '../user/user.module';
import { ChallengeGateway } from './challenge.gateway';
import { ChallengeService } from './challenge.service';

@Module({
  imports: [
    MikroOrmModule.forFeature([Challenge, PrevChallenge]),
    forwardRef(() => EventModule),
    UserModule,
    RewardModule,
    ClientModule,
  ],
  providers: [ChallengeGateway, ChallengeService],
})
export class ChallengeModule {}
