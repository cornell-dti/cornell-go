import { Test, TestingModule } from '@nestjs/testing';
import { RewardService } from './reward.service';
import { PrismaModule } from '../prisma/prisma.module';
import { ClientModule } from '../client/client.module';

describe('RewardService', () => {
  let service: RewardService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [PrismaModule, ClientModule],
      providers: [RewardService],
    }).compile();

    service = module.get<RewardService>(RewardService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
