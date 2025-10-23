import { Module } from '@nestjs/common';
import { QuizService } from './quiz.service';
import { QuizGateway } from './quiz.gateway';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  providers: [QuizService, QuizGateway, PrismaService],
  exports: [QuizService],
})
export class QuizModule {}
