import { Test, TestingModule } from '@nestjs/testing';
import { RewardService } from './reward.service';
import { ClientService } from '../client/client.service';
import { PrismaService } from '../prisma/prisma.service';

describe('RewardService', () => {
  let service: RewardService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RewardService,
        {
          useValue: null,
          provide: ClientService,
        },
        {
          useValue: null,
          provide: PrismaService,
        },
      ],
    }).compile();

    service = module.get<RewardService>(RewardService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
