import { SessionLogModule } from './../session-log/session-log.module';
import { forwardRef, Module } from '@nestjs/common';
import { ClientModule } from '../client/client.module';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';
import { EventModule } from '../event/event.module';
import { OrganizationModule } from '../organization/organization.module';
import { PrismaModule } from '../prisma/prisma.module';
import { GroupGateway } from './group.gateway';
import { GroupService } from './group.service';
import { CaslModule } from '../casl/casl.module';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    forwardRef(() => UserModule),
    ClientModule,
    forwardRef(() => EventModule),
    PrismaModule,
    SessionLogModule,
    OrganizationModule,
    CaslModule,
  ],
  providers: [GroupService, GroupGateway],
  exports: [GroupService, GroupGateway],
})
export class GroupModule {}
