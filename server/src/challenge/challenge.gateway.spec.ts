import { Test, TestingModule } from '@nestjs/testing';
import { ChallengeGateway } from './challenge.gateway';
import { ClientModule } from '../client/client.module';
import { ChallengeService } from './challenge.service';
import { UserModule } from '../user/user.module';
import { GroupModule } from '../group/group.module';
import { EventModule } from '../event/event.module';
import { RewardModule } from '../reward/reward.module';
import { SessionLogModule } from '../session-log/session-log.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';

describe('ChallengeGateway', () => {
  let gateway: ChallengeGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [
        ClientModule,
        UserModule,
        GroupModule,
        EventModule,
        RewardModule,
        SessionLogModule,
        PrismaModule,
        AuthModule,
      ],
      providers: [ChallengeGateway, ChallengeService],
    }).compile();

    gateway = module.get<ChallengeGateway>(ChallengeGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});
