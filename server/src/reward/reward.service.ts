import { Injectable } from '@nestjs/common';
import { EventReward, PrismaClient, User } from '@prisma/client';
import { ClientService } from 'src/client/client.service';
import { PrismaService } from '../prisma/prisma.service';
import { RewardDto, UpdateRewardDataDto } from './reward.dto';

@Injectable()
export class RewardService {
  constructor(
    private prisma: PrismaService,
    private clientService: ClientService,
  ) {}

  /** Get rewards that are in ids and owned by the user */
  async getRewardsForUser(user: User, ids: string[]): Promise<EventReward[]> {
    return await this.prisma.eventReward.findMany({
      where: {
        id: { in: ids },
        userId: user.id,
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
        userId: null,
      },
    });
  }

  async dtoForReward(rw: EventReward, restricted: boolean): Promise<RewardDto> {
    return {
      id: rw.id,
      eventId: rw.eventId,
      description: rw.description,
      userId: restricted ? undefined : rw.userId ?? undefined,
      redeemInfo: restricted ? undefined : rw.redeemInfo,
      isRedeemed: restricted ? undefined : rw.isRedeemed,
      isAchievement: rw.isAchievement,
      points: rw.points
    };
  }

  async emitUpdateRewardData(
    rw: EventReward,
    deleted: boolean,
    admin?: boolean,
    user?: User,
  ) {
    const restrictedDto: UpdateRewardDataDto = {
      reward: deleted ? rw.id : await this.dtoForReward(rw, true),
      deleted,
    };

    const unrestrictedDto: UpdateRewardDataDto = {
      reward: deleted ? rw.id : await this.dtoForReward(rw, false),
      deleted,
    };

    if (user) {
      this.clientService.sendUpdate(
        'updateRewardData',
        user.id,
        !!admin,
        admin ? unrestrictedDto : restrictedDto,
      );
    } else {
      this.clientService.sendUpdate(
        'updateRewardData',
        rw.id,
        false,
        restrictedDto,
      );

      this.clientService.sendUpdate(
        'updateRewardData',
        rw.id,
        true,
        unrestrictedDto,
      );
    }
  }

  /** Deletes all rewards with IDs listed in removeIds.
   * Does nothing if the reward's ID is not in the user's rewards. */
  async removeReward(id: string, accessor: User) {
    await this.prisma.eventReward.delete({
      where: {
        id,
      },
    });
  }

  /** Creates a EventReward given RewardDto reward */
  async upsertRewardFromDto(reward: RewardDto) {
    let rewardEntity = await this.prisma.eventReward.findFirst({
      where: { id: reward.id },
    });

    if (rewardEntity) {
      rewardEntity = await this.prisma.eventReward.update({
        where: { id: reward.id },
        data: {
          description: reward.description.substring(0, 2048),
          redeemInfo: reward.redeemInfo!.substring(0, 2048),
          isAchievement: reward.isAchievement,
          points: reward.points,
        },
      });
    } else {
      rewardEntity = await this.prisma.eventReward.create({
        data: {
          eventId: reward.eventId,
          eventIndex: -10,
          description: reward.description.substring(0, 2048),
          redeemInfo: reward.redeemInfo!.substring(0, 2048),
          isRedeemed: false,
          isAchievement: reward.isAchievement,
          points: reward.points,
        },
      });
      if (rewardEntity.eventIndex === -10) {
        const maxIndexReward = await this.prisma.eventReward.findFirst({
          where: { eventId: reward.eventId },
          orderBy: { eventIndex: 'desc' },
        });

        await this.prisma.eventReward.update({
          where: { id: rewardEntity.id },
          data: {
            eventIndex: Math.max((maxIndexReward?.eventIndex ?? -1) + 1, 0),
          },
        });
      }
    }

    return rewardEntity;
  }

  async getRewardById(id: string) {
    return await this.prisma.eventReward.findFirstOrThrow({ where: { id } });
  }
}
