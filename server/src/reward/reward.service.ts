import { Injectable } from '@nestjs/common';
import { EventReward, PrismaClient, User } from '@prisma/client';

@Injectable()
export class RewardService {
  constructor(private prisma: PrismaClient) {}

  /** Get rewards that are in ids and owned by the user */
  async getRewardsForUser(user: User, ids: string[]): Promise<EventReward[]> {
    return await this.prisma.eventReward.findMany({
      where: {
        id: { in: ids },
        user: user,
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
        user: { isNot: user },
      },
    });
  }
}
