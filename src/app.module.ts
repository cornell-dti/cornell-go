import { Module } from '@nestjs/common';
import { EventsModule } from './events/events.module';
import { GroupsModule } from './groups/groups.module';
import { ChallengesModule } from './challenges/challenges.module';
import { UsersModule } from './users/users.module';
import { AdminModule } from './admin/admin.module';
import { LeadersModule } from './leaders/leaders.module';
import { AuthModule } from './auth/auth.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './model/user.entity';
import { Challenge } from './model/challenge.entity';
import { EventBase } from './model/event-base.entity';
import { EventProgress } from './model/event-progress.entity';
import { GroupMember } from './model/group-member.entity';
import { Group } from './model/group.entity';
import { PrevChallenge } from './model/prev-challenge.entity';
import { EventReward } from './model/event-reward.entity';
import { SessionLogEntry } from './model/session-log-entry.entity';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.CORNELLGODB_HOST,
      username: process.env.CORNELLGODB_USER,
      password: process.env.CORNELLGODB_PASS,
      database: process.env.CORNELLGODB_DBNAME,
      schema: process.env.CORNELLGODB_SCHEMA,
      logNotifications: true,
      cache: true,
      entities: [
        User,
        Group,
        GroupMember,
        Challenge,
        PrevChallenge,
        EventBase,
        EventReward,
        EventProgress,
        SessionLogEntry,
      ],
    }),
    EventsModule,
    GroupsModule,
    ChallengesModule,
    UsersModule,
    AdminModule,
    LeadersModule,
    AuthModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
