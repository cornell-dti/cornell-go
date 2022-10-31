import { SessionLogModule } from './../session-log/session-log.module';
import { EventService } from 'src/event/event.service';
import { forwardRef, Module } from '@nestjs/common';
import { GroupService } from './group.service';
import { GroupGateway } from './group.gateway';
import { UserModule } from '../user/user.module';
import { ClientModule } from 'src/client/client.module';
import { EventModule } from '../event/event.module';
import { AuthModule } from 'src/auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [ClientModule, EventModule, SessionLogModule, PrismaModule],
  providers: [GroupService, GroupGateway],
  exports: [GroupService, GroupGateway],
})
export class GroupModule {}
