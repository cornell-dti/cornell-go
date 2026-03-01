import { Module } from '@nestjs/common';
import { ClientModule } from '../client/client.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { CampusEventService } from './campus-event.service';
import { CampusEventGateway } from './campus-event.gateway';

@Module({
  imports: [AuthModule, ClientModule, PrismaModule],
  providers: [CampusEventService, CampusEventGateway],
  exports: [CampusEventService, CampusEventGateway],
})
export class CampusEventModule {}
