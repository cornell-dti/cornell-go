import { PrismaModule } from './../prisma/prisma.module';
import { Module } from '@nestjs/common';
import { SessionLogService } from './session-log.service';

@Module({
  imports: [PrismaModule],
  exports: [SessionLogService],
  providers: [SessionLogService],
})
export class SessionLogModule {}