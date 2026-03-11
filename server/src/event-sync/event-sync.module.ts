import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ClientModule } from '../client/client.module';
import { AuthModule } from '../auth/auth.module';
import { CaslModule } from '../casl/casl.module';
import { EventSyncService } from './event-sync.service';
import { EventSyncGateway } from './event-sync.gateway';

@Module({
  imports: [PrismaModule, ClientModule, AuthModule, CaslModule],
  providers: [EventSyncService, EventSyncGateway],
  exports: [EventSyncService],
})
export class EventSyncModule {}
