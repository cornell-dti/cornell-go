import { Module, forwardRef } from '@nestjs/common';
import { QuizService } from './quiz.service';
import { QuizGateway } from './quiz.gateway';
import { PrismaService } from '../prisma/prisma.service';
import { AuthModule } from '../auth/auth.module';
import { EventModule } from '../event/event.module';
import { UserModule } from '../user/user.module';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    forwardRef(() => EventModule),
    forwardRef(() => UserModule),
  ],
  providers: [QuizService, QuizGateway, PrismaService],
  exports: [QuizService],
})
export class QuizModule { }
