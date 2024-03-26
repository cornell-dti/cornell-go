import { Module, OnModuleInit, UseFilters } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { ChallengeModule } from './challenge/challenge.module';
import { EventModule } from './event/event.module';
import { GroupModule } from './group/group.module';
import { UserModule } from './user/user.module';

import { ConfigModule } from '@nestjs/config';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
import { ClientModule } from './client/client.module';
import { PrismaModule } from './prisma/prisma.module';
import { SessionLogModule } from './session-log/session-log.module';
import { OrganizationModule } from './organization/organization.module';
import { AchievementModule } from './achievement/achievement.module';
import { CaslModule } from './casl/casl.module';

@Module({
  imports: [
    ConfigModule.forRoot(),
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, '..', '..', 'admin', 'build'),
    }),
    AuthModule,
    ClientModule,
    UserModule,
    EventModule,
    AchievementModule,
    GroupModule,
    ChallengeModule,
    PrismaModule,
    SessionLogModule,
    OrganizationModule,
    CaslModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
