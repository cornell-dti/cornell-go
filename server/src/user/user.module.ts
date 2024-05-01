import { SessionLogModule } from './../session-log/session-log.module';
import { forwardRef, Module } from '@nestjs/common';
import { ClientModule } from '../client/client.module';
import { AuthModule } from '../auth/auth.module';
import { EventModule } from '../event/event.module';
import { GroupModule } from '../group/group.module';
import { OrganizationModule } from '../organization/organization.module';
import { PrismaModule } from '../prisma/prisma.module';
import { UserGateway } from './user.gateway';
import { UserService } from './user.service';
import { CaslModule } from '../casl/casl.module';
import { AchievementModule } from '../achievement/achievement.module';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    forwardRef(() => GroupModule),
    SessionLogModule,
    ClientModule,
    PrismaModule,
    EventModule,
    OrganizationModule,
    AchievementModule,
    CaslModule,
  ],
  providers: [UserService, UserGateway],
  exports: [UserService, UserGateway],
})
export class UserModule {}
