import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RewardModule } from 'src/reward/reward.module';
import { Challenge } from '../model/challenge.entity';
import { PrevChallenge } from '../model/prev-challenge.entity';
import { UserModule } from '../user/user.module';
import { ChallengeGateway } from './challenge.gateway';
import { ChallengeService } from './challenge.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Challenge, PrevChallenge]),
    UserModule,
    RewardModule,
  ],
  providers: [ChallengeGateway, ChallengeService],
})
export class ChallengeModule {}
