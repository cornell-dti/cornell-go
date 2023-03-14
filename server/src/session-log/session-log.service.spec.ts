import { Test, TestingModule } from '@nestjs/testing';
import { SessionLogService } from './session-log.service';

describe('SessionLogService', () => {
  let service: SessionLogService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [SessionLogService],
    }).compile();

    service = module.get<SessionLogService>(SessionLogService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});