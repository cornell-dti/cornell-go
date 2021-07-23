import { Module } from '@nestjs/common';
import { EventsModule } from './events/events.module';
import { GroupsModule } from './groups/groups.module';
import { ChallengesModule } from './challenges/challenges.module';
import { UsersModule } from './users/users.module';
import { AdminModule } from './admin/admin.module';
import { AuthModule } from './auth/auth.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';

@Module({
  imports: [
    ConfigModule.forRoot(),
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.CORNELLGODB_HOST,
      username: process.env.CORNELLGODB_USER,
      password: process.env.CORNELLGODB_PASS,
      database: process.env.CORNELLGODB_DBNAME,
      schema: process.env.CORNELLGODB_SCHEMA,
      logNotifications: true,
      cache: true,
      entities: ['dist/model/*.entity{.ts,.js}'],
      migrations: ['dist/migration/*{.ts,.js}'],
      migrationsRun: true,
    }),
    EventsModule,
    GroupsModule,
    ChallengesModule,
    UsersModule,
    AdminModule,
    AuthModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
