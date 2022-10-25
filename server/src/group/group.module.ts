import { Module } from '@nestjs/common';
import { ClientModule } from 'src/client/client.module';
import { EventModule } from '../event/event.module';
import { PrismaModule } from '../prisma/prisma.module';
import { GroupGateway } from './group.gateway';
import { GroupService } from './group.service';

@Module({
  imports: [ClientModule, EventModule, PrismaModule],
  providers: [GroupService, GroupGateway],
  exports: [GroupService, GroupGateway],
})
export class GroupModule {}
