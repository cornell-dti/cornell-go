import { Module } from '@nestjs/common';
import { EventModule } from './event/event.module';
import { GroupModule } from './group/group.module';
import { ChallengeModule } from './challenge/challenge.module';
import { UserModule } from './user/user.module';
import { AdminModule } from './admin/admin.module';
import { AuthModule } from './auth/auth.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { RewardGateway } from './reward/reward.gateway';
import { RewardModule } from './reward/reward.module';

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
    EventModule,
    GroupModule,
    ChallengeModule,
    UserModule,
    AdminModule,
    AuthModule,
    RewardModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
