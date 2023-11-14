import { forwardRef, Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ClientModule } from '../client/client.module';
import { EventModule } from '../event/event.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AchievementGateway } from './achievements.gateway';
import { AchievementService } from './achievements.service';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    ClientModule,
    EventModule,
    PrismaModule,
  ],
  exports: [AchievementService],
  providers: [AchievementGateway, AchievementService],
})
export class AchievementsModule {}
