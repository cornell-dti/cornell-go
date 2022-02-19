import { Module } from '@nestjs/common';
import { EventModule } from './event/event.module';
import { GroupModule } from './group/group.module';
import { ChallengeModule } from './challenge/challenge.module';
import { UserModule } from './user/user.module';
import { AdminModule } from './admin/admin.module';
import { AuthModule } from './auth/auth.module';

import { ConfigModule } from '@nestjs/config';
import { RewardGateway } from './reward/reward.gateway';
import { RewardModule } from './reward/reward.module';
import { ClientModule } from './client/client.module';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
import { MikroOrmModule } from '@mikro-orm/nestjs';
import { EntityManager } from '@mikro-orm/postgresql';
import { AsyncLocalStorage } from 'async_hooks';

const storage = new AsyncLocalStorage<EntityManager>();

@Module({
  imports: [
    ConfigModule.forRoot(),
    MikroOrmModule.forRoot({
      type: 'postgresql',
      entities: ['dist/model/*.entity{.ts,.js}'],
      entitiesTs: ['src/model/*.entity{.ts,.js}'],
      name: 'CornellGO PostgreSQL DB',
      clientUrl: process.env.DATABASE_URL,
      forceUtcTimezone: true,
      validate: true,
      strict: true,
      debug: true,
      persistOnCreate: true,
      registerRequestContext: false, // disable automatatic middleware
      context: () => storage.getStore(), // use our AsyncLocalStorage instance
      driverOptions: {
        connection: {
          ssl: !process.env.NO_SSL,
          rejectUnauthorized: !process.env.NO_SSL,
        },
      },
      migrations: {
        path: 'dist/migrations',
        pathTs: 'src/migrations',
      },
    }),
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, '..', '..', 'admin', 'build'),
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
