import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  FeedbackCategoryDto,
  FeedbackDto,
  SubmitFeedbackDto,
} from './feedback.dto';

@Injectable()
export class FeedbackService {
  constructor(private readonly prisma: PrismaService) {}

  async createFeedback(userId: string, dto: SubmitFeedbackDto) {
    if (dto.challengeId) {
      return this.prisma.feedback.upsert({
        where: {
          userId_challengeId: { userId, challengeId: dto.challengeId },
        },
        update: {
          category: dto.category,
          text: dto.text,
          rating: dto.rating,
        },
        create: {
          userId,
          category: dto.category,
          text: dto.text,
          rating: dto.rating,
          challengeId: dto.challengeId,
        },
      });
    }

    return this.prisma.feedback.create({
      data: {
        userId,
        category: dto.category,
        text: dto.text,
        rating: dto.rating,
      },
    });
  }

  async getAllFeedback(): Promise<FeedbackDto[]> {
    const feedbacks = await this.prisma.feedback.findMany({
      include: { user: { select: { username: true } } },
      orderBy: { createdAt: 'desc' },
    });

    const challengeIds = feedbacks
      .map(f => f.challengeId)
      .filter((id): id is string => id != null);

    const challenges =
      challengeIds.length > 0
        ? await this.prisma.challenge.findMany({
            where: { id: { in: challengeIds } },
            select: { id: true, name: true },
          })
        : [];

    const challengeMap = new Map(challenges.map(c => [c.id, c.name]));

    return feedbacks.map(f => ({
      id: f.id,
      createdAt: f.createdAt.toISOString(),
      category: f.category as unknown as FeedbackCategoryDto,
      text: f.text,
      rating: f.rating != null ? f.rating : undefined,
      challengeId: f.challengeId ?? undefined,
      userId: f.userId,
      username: f.user.username,
      challengeName: f.challengeId
        ? challengeMap.get(f.challengeId)
        : undefined,
    }));
  }
}
