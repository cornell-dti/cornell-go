import { Module } from '@nestjs/common';
import { ClubSubmissionController } from './club-submission.controller';
import { ClubSubmissionService } from './club-submission.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [ClubSubmissionController],
  providers: [ClubSubmissionService]
})
export class ClubSubmissionModule {}
