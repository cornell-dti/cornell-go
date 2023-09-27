import { Test, TestingModule } from '@nestjs/testing';
import { SessionLogService } from './session-log.service';
import { PrismaService } from '../prisma/prisma.service';

describe('SessionLogService', () => {
  let service: SessionLogService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SessionLogService,
        {
          useValue: null,
          provide: PrismaService,
        },
      ],
    }).compile();

    service = module.get<SessionLogService>(SessionLogService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
