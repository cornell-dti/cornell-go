import { forwardRef, Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ClientModule } from '../client/client.module';
import { EventModule } from '../event/event.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AchievementGateway } from './achievement.gateway';
import { AchievementService } from './achievement.service';
import { CaslModule } from '../casl/casl.module';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    forwardRef(() => CaslModule),
    ClientModule,
    EventModule,
    PrismaModule,
  ],
  exports: [AchievementService],
  providers: [AchievementGateway, AchievementService],
})
export class AchievementModule {}
