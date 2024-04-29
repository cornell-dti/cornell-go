import { forwardRef, Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ClientModule } from '../client/client.module';
import { EventModule } from '../event/event.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AchievementGateway } from './achievement.gateway';
import { AchievementService } from './achievement.service';
import { CaslModule } from '../casl/casl.module';
import { OrganizationModule } from '../organization/organization.module';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    ClientModule,
    EventModule,
    PrismaModule,
    CaslModule,
    OrganizationModule,
  ],
  exports: [AchievementService],
  providers: [AchievementGateway, AchievementService],
})
export class AchievementModule {}
