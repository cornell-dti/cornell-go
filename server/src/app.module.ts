import { Module, OnModuleInit, UseFilters } from '@nestjs/common';]
import { Module } from '@nestjs/common';
import { AdminModule } from './admin/admin.module';
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
import { RewardModule } from './reward/reward.module';

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
    GroupModule,
    ChallengeModule,
    AdminModule,
    RewardModule,
    PrismaModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
