import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SubmitFeedbackDto } from './feedback.dto';

@Injectable()
export class FeedbackService {
  constructor(private readonly prisma: PrismaService) {}

  async createFeedback(userId: string, dto: SubmitFeedbackDto) {
    return this.prisma.feedback.create({
      data: {
        userId,
        category: dto.category,
        text: dto.text,
        rating: dto.rating,
        challengeId: dto.challengeId,
      },
    });
  }
}
