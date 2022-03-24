import { Test, TestingModule } from '@nestjs/testing';
import { AdminCallbackService } from './admin-callback.service';

describe('AdminCallbackService', () => {
  let service: AdminCallbackService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [AdminCallbackService],
    }).compile();

    service = module.get<AdminCallbackService>(AdminCallbackService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
