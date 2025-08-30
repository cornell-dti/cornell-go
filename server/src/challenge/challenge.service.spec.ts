import { Test, TestingModule } from '@nestjs/testing';
import { ChallengeService } from './challenge.service';
import { SessionLogService } from '../session-log/session-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventService } from '../event/event.service';
import { ClientService } from '../client/client.service';
import { AchievementService } from '../achievement/achievement.service';
import { CaslAbilityFactory } from '../casl/casl-ability.factory';

describe('ChallengeService', () => {
  let service: ChallengeService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ChallengeService,
        {
          useValue: null,
          provide: SessionLogService,
        },
        {
          useValue: null,
          provide: PrismaService,
        },
        {
          useValue: null,
          provide: EventService,
        },
        {
          useValue: null,
          provide: AchievementService,
        },
        {
          useValue: null,
          provide: ClientService,
        },
        {
          useValue: null,
          provide: CaslAbilityFactory,
        },
      ],
    }).compile();

    service = module.get<ChallengeService>(ChallengeService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
