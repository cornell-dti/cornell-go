import { Module, forwardRef } from '@nestjs/common';
import { QuizService } from './quiz.service';
import { QuizGateway } from './quiz.gateway';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { EventModule } from '../event/event.module';
import { UserModule } from '../user/user.module';
import { ClientModule } from '../client/client.module';
import { CaslModule } from '../casl/casl.module';

@Module({
  imports: [
    PrismaModule,
    forwardRef(() => AuthModule),
    forwardRef(() => EventModule),
    forwardRef(() => UserModule),
    ClientModule,
    CaslModule,
  ],
  providers: [QuizService, QuizGateway],
  exports: [QuizService],
})
export class QuizModule {}
