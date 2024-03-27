import { PrismaModule } from './../prisma/prisma.module';
import { Module } from '@nestjs/common';
import { SessionLogService } from './session-log.service';
import { CaslModule } from '../casl/casl.module';

@Module({
  imports: [PrismaModule, CaslModule],
  exports: [SessionLogService],
  providers: [SessionLogService],
})
export class SessionLogModule {}
