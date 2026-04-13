import { Module, OnModuleInit, UseFilters } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { ChallengeModule } from './challenge/challenge.module';
import { EventModule } from './event/event.module';
import { GroupModule } from './group/group.module';
import { UserModule } from './user/user.module';

import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
import { ClientModule } from './client/client.module';
import { PrismaModule } from './prisma/prisma.module';
import { SessionLogModule } from './session-log/session-log.module';
import { OrganizationModule } from './organization/organization.module';
import { AchievementModule } from './achievement/achievement.module';
import { CaslModule } from './casl/casl.module';
import { AvatarModule } from './avatar/avatar.module';
import { NotificationModule } from './notification/notification.module';
import { TimerModule } from './timer/timer.module';
import { QuizModule } from './quiz/quiz.module';
import { CheckInModule } from './check-in/check-in.module';
import { EventSyncModule } from './event-sync/event-sync.module';
import { ClubSubmissionModule } from './club-submission/club-submission.module';
import { SpotlightModule } from './spotlight/spotlight.module';

@Module({
  imports: [
    ConfigModule.forRoot(),
    ScheduleModule.forRoot(),
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, '..', '..', '..', 'admin', 'build'),
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
    AvatarModule,
    NotificationModule,
    TimerModule,
    QuizModule,
    CheckInModule,
    EventSyncModule,
    ClubSubmissionModule,
    SpotlightModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
