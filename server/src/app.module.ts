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
import { ClientModule } from './client/client.module';

import * as PgParser from 'pg-connection-string';

const connectionOptions = process.env.DATABASE_URL
  ? PgParser.parse(process.env.DATABASE_URL)
  : null;

@Module({
  imports: [
    ConfigModule.forRoot(),
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: connectionOptions?.host ?? process.env.CORNELLGODB_HOST,
      port: connectionOptions?.port ?? 5432,
      username: connectionOptions?.user ?? process.env.CORNELLGODB_USER,
      password: connectionOptions?.password ?? process.env.CORNELLGODB_PASS,
      database: connectionOptions?.database ?? process.env.CORNELLGODB_DBNAME,
      schema: process.env.CORNELLGODB_SCHEMA,
      synchronize: process.env.DEVELOPMENT === 'true',
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
    ClientModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
