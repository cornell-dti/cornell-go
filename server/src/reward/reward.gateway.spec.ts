import { Test, TestingModule } from '@nestjs/testing';
import { RewardGateway } from './reward.gateway';
import { ClientModule } from '../client/client.module';
import { RewardModule } from './reward.module';
import { EventModule } from '../event/event.module';
import { AuthModule } from '../auth/auth.module';

describe('RewardGateway', () => {
  let gateway: RewardGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [ClientModule, RewardModule, EventModule, AuthModule],
      providers: [RewardGateway],
    }).compile();

    gateway = module.get<RewardGateway>(RewardGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});
