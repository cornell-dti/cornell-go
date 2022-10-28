import { Module, OnModuleInit, UseFilters } from '@nestjs/common';
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
import { InitService } from './init.service';
import { TsMorphMetadataProvider } from '@mikro-orm/reflection';

@Module({
  imports: [
    ConfigModule.forRoot(),
    MikroOrmModule.forRoot({
      type: 'postgresql',
      autoLoadEntities: true,
      allowGlobalContext: true,
      metadataProvider: TsMorphMetadataProvider,
      name: 'CornellGO PostgreSQL DB',
      clientUrl: process.env.DATABASE_URL,
      forceUtcTimezone: true,
      validate: true,
      strict: true,
      debug: true,
      persistOnCreate: true,
      driverOptions: {
        connection: {
          ssl: !process.env.NO_SSL && { rejectUnauthorized: false },
        },
      },
      migrations: {
        path: 'dist/src/migrations',
        pathTs: 'src/migrations',
        disableForeignKeys: false,
      },
      schemaGenerator: {
        disableForeignKeys: false,
      },
    }),
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, '..', '..', '..', 'admin', 'build'),
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
  providers: [InitService],
})
export class AppModule {}
