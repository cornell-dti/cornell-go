import { Test, TestingModule } from '@nestjs/testing';
import { ClubSubmissionController } from './club-submission.controller';

describe('ClubSubmissionController', () => {
  let controller: ClubSubmissionController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ClubSubmissionController],
    }).compile();

    controller = module.get<ClubSubmissionController>(ClubSubmissionController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
