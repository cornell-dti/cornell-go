import { forwardRef, Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ClientModule } from '../client/client.module';
import { AuthModule } from '../auth/auth.module';
import { CaslModule } from '../casl/casl.module';
import { TimerService } from './timer.service';
import { TimerGateway } from './timer.gateway';
import { ChallengeModule } from '../challenge/challenge.module';

@Module({
  imports: [
    PrismaModule,
    ClientModule,
    forwardRef(() => AuthModule),
    CaslModule,
    forwardRef(() => ChallengeModule),
  ],
  providers: [TimerService, TimerGateway],
  exports: [TimerService],
})
export class TimerModule {}
