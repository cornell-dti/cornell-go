import { Module } from '@nestjs/common';
import { ClubSubmissionController } from './club-submission/club-submission.controller';
import { ClubSubmissionService } from './club-submission/club-submission.service';

@Module({
  controllers: [ClubSubmissionController],
  providers: [ClubSubmissionService]
})
export class ClubSubmissionModule {}
