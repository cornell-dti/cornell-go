import { Test, TestingModule } from '@nestjs/testing';
import { ClubSubmissionService } from './club-submission.service';

describe('ClubSubmissionService', () => {
  let service: ClubSubmissionService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ClubSubmissionService],
    }).compile();

    service = module.get<ClubSubmissionService>(ClubSubmissionService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
