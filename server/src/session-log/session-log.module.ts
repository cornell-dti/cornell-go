import { Module } from '@nestjs/common';
import { SessionLogService } from './session-log.service';

@Module({
  providers: [SessionLogService],
})
export class SessionLogModule {}
