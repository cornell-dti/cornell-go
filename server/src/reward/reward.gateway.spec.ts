import { Test, TestingModule } from '@nestjs/testing';
import { RewardGateway } from './reward.gateway';

describe('RewardGateway', () => {
  let gateway: RewardGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [RewardGateway],
    }).compile();

    gateway = module.get<RewardGateway>(RewardGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});
