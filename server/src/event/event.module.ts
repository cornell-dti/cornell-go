import { Module } from '@nestjs/common';
import { ClientModule } from 'src/client/client.module';
import { PrismaModule } from '../prisma/prisma.module';
import { EventGateway } from './event.gateway';
import { EventService } from './event.service';

@Module({
  imports: [ClientModule, PrismaModule],
  providers: [EventService, EventGateway],
  exports: [EventService, EventGateway],
})
export class EventModule {}
