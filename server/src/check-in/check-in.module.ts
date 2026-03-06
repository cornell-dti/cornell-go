import { Module, forwardRef } from '@nestjs/common';
import { CheckInService } from './check-in.service';
import { CheckInGateway } from './check-in.gateway';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { EventModule } from '../event/event.module';
import { UserModule } from '../user/user.module';

@Module({
  imports: [
    PrismaModule,
    forwardRef(() => AuthModule),
    forwardRef(() => EventModule),
    forwardRef(() => UserModule),
  ],
  providers: [CheckInService, CheckInGateway],
  exports: [CheckInService],
})
export class CheckInModule {}

