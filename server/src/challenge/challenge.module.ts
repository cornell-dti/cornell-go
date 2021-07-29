import { Module } from '@nestjs/common';
import { ChallengeGateway } from './challenge.gateway';

@Module({
  providers: [ChallengeGateway]
})
export class ChallengeModule {}
