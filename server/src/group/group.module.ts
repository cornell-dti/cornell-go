import { SessionLogModule } from './../session-log/session-log.module';
import { forwardRef, Module } from '@nestjs/common';
import { ClientModule } from 'src/client/client.module';
import { UserModule } from 'src/user/user.module';
import { AuthModule } from '../auth/auth.module';
import { EventModule } from '../event/event.module';
import { OrganizationModule } from '../organization/organization.module';
import { PrismaModule } from '../prisma/prisma.module';
import { GroupGateway } from './group.gateway';
import { GroupService } from './group.service';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    ClientModule,
    forwardRef(() => UserModule),
    EventModule,
    PrismaModule,
    SessionLogModule,
    OrganizationModule,
  ],
  providers: [GroupService, GroupGateway],
  exports: [GroupService, GroupGateway],
})
export class GroupModule {}
