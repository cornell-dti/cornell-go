import { Test, TestingModule } from '@nestjs/testing';
import { ChallengeGateway } from './challenge.gateway';

describe('ChallengeGateway', () => {
  let gateway: ChallengeGateway;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ChallengeGateway],
    }).compile();

    gateway = module.get<ChallengeGateway>(ChallengeGateway);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });
});
