import { Module, forwardRef } from '@nestjs/common';
import { SpotlightService } from './spotlight.service';
import { SpotlightGateway } from './spotlight.gateway';
import { SpotlightController } from './spotlight.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { NotificationModule } from '../notification/notification.module';

@Module({
  imports: [PrismaModule, forwardRef(() => AuthModule), NotificationModule],
  controllers: [SpotlightController],
  providers: [SpotlightService, SpotlightGateway],
  exports: [SpotlightService],
})
export class SpotlightModule {}
