import { Injectable } from '@nestjs/common';
import { EventReward, PrismaClient, User } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class RewardService {
  constructor(private prisma: PrismaService) {}

  /** Get rewards that are in ids and owned by the user */
  async getRewardsForUser(user: User, ids: string[]): Promise<EventReward[]> {
    return await this.prisma.eventReward.findMany({
      where: {
        id: { in: ids },
        userId: { not: user.id },
      },
    });
  }

  /** Get rewards that are in ids and not owned by the user */
  async getRewardsNotForUser(
    user: User,
    ids: string[],
  ): Promise<EventReward[]> {
    return await this.prisma.eventReward.findMany({
      where: {
        id: { in: ids },
        userId: { not: user.id },
      },
    });
  }
}
