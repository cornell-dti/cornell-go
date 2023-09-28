import { Test, TestingModule } from '@nestjs/testing';
import { ChallengeGateway } from './challenge.gateway';
import { ClientService } from '../client/client.service';
import { ChallengeService } from './challenge.service';
import { UserService } from '../user/user.service';
import { GroupService } from '../group/group.service';
import { EventService } from '../event/event.service';
import { RewardService } from '../reward/reward.service';
import { AuthService } from '../auth/auth.service';

describe('ChallengeGateway', () => {
  let gateway: ChallengeGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ChallengeGateway,
        {
          useValue: null,
          provide: ClientService,
        },
        {
          useValue: null,
          provide: ChallengeService,
        },
        {
          useValue: null,
          provide: UserService,
        },
        {
          useValue: null,
          provide: GroupService,
        },
        {
          useValue: null,
          provide: EventService,
        },
        {
          useValue: null,
          provide: RewardService,
        },
        {
          useValue: null,
          provide: AuthService,
        },
      ],
    }).compile();

    gateway = module.get<ChallengeGateway>(ChallengeGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});
