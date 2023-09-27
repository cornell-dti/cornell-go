import { Test, TestingModule } from '@nestjs/testing';
import { RewardGateway } from './reward.gateway';
import { ClientService } from '../client/client.service';
import { RewardService } from './reward.service';
import { EventService } from '../event/event.service';
import { AuthService } from '../auth/auth.service';

describe('RewardGateway', () => {
  let gateway: RewardGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RewardGateway,
        {
          useValue: null,
          provide: ClientService,
        },
        {
          useValue: null,
          provide: RewardService,
        },
        {
          useValue: null,
          provide: EventService,
        },
        {
          useValue: null,
          provide: AuthService,
        },
      ],
    }).compile();

    gateway = module.get<RewardGateway>(RewardGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});
