import { SessionLogModule } from './../session-log/session-log.module';
import { EventService } from 'src/event/event.service';
import { forwardRef, Module } from '@nestjs/common';
import { ClientModule } from 'src/client/client.module';
import { AuthModule } from '../auth/auth.module';
import { EventModule } from '../event/event.module';
import { PrismaModule } from '../prisma/prisma.module';
import { GroupGateway } from './group.gateway';
import { GroupService } from './group.service';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    ClientModule,
    EventModule,
    PrismaModule,
    SessionLogModule,
  ],
  providers: [GroupService, GroupGateway],
  exports: [GroupService, GroupGateway],
})
export class GroupModule {}
