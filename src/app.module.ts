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

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.CORNELLGODB_HOST,
      username: process.env.CORNELLGODB_USER,
      password: process.env.CORNELLGODB_PASS,
      database: process.env.CORNELLGODB_NAME,
      logNotifications: true,
      cache: true,
      entities: [User],
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
