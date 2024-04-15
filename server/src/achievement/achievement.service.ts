import { SessionLogService } from './../session-log/session-log.service';
import { Injectable } from '@nestjs/common';
import {
  $Enums,
  Achievement,
  AchievementTracker,
  LocationType,
  PrismaClient,
  User,
} from '@prisma/client';
import { ClientService } from '../client/client.service';
import { PrismaService } from '../prisma/prisma.service';
import { accessibleBy } from '@casl/prisma';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';
import { Action } from '../casl/action.enum';
import { subject } from '@casl/ability';
import { defaultAchievementData } from '../organization/organization.service';
import {
  AchievementType,
  AchievementDto,
  LocationType as LocType,
  AchievementTrackerDto,
  UpdateAchievementDataDto,
} from './achievement.dto';

@Injectable()
export class AchievementService {
  constructor(
    private readonly prisma: PrismaService,
    private clientService: ClientService,
    private abilityFactory: CaslAbilityFactory,
  ) {}

  /** get an achievement by its id */
  async getAchievementFromId(id: string) {
    return await this.prisma.achievement.findFirstOrThrow({ where: { id } });
  }

  /** get list of achievements by IDs */
  async getAchievementsByIdsForAbility(
    ability: AppAbility,
    ids: string[],
  ): Promise<Achievement[]> {
    return await this.prisma.achievement.findMany({
      where: {
        AND: [
          { id: { in: ids } },
          accessibleBy(ability, Action.Read).Achievement,
        ],
      },
    });
  }

  /** upsert achievement */
  async upsertAchievementFromDto(
    ability: AppAbility,
    achievement: AchievementDto,
  ) {
    let ach = await this.prisma.achievement.findFirst({
      where: { id: achievement.id },
    });

    if (
      ach &&
      (await this.prisma.achievement.findFirst({
        select: { id: true },
        where: {
          AND: [
            accessibleBy(ability, Action.Update).Achievement,
            { id: ach.id },
          ],
        },
      }))
    ) {
      const assignData = {
        requiredPoints: achievement.requiredPoints,
        name: achievement.name?.substring(0, 2048),
        description: achievement.description?.substring(0, 2048),
        imageUrl: achievement.imageUrl?.substring(0, 2048),
        locationType: achievement.locationType as LocationType,
        achievementType: achievement.achievementType as AchievementType,
      };

      const data = await this.abilityFactory.filterInaccessible(
        assignData,
        subject('Achievement', ach),
        ability,
        Action.Update,
      );

      ach = await this.prisma.achievement.update({
        where: { id: ach.id },
        data,
      });
    } else if (!ach && ability.can(Action.Create, 'Achievement')) {
      const data = {
        name:
          achievement.name?.substring(0, 2048) ?? defaultAchievementData.name,
        description:
          achievement.description?.substring(0, 2048) ??
          defaultAchievementData.description,
        imageUrl:
          achievement.imageUrl?.substring(0, 2048) ??
          defaultAchievementData.imageUrl,
        locationType: achievement.locationType as LocationType,
        achievementType: achievement.achievementType as AchievementType,
        eventIndex: achievement.eventId ?? 0, // check
        requiredPoints: achievement.requiredPoints ?? 0,
      };

      ach = await this.prisma.achievement.create({
        data,
      });

      console.log(`Created achievement ${ach.id}`);
    } else {
      return null;
    }
    return ach;
  }

  /** removes achievement by ID */
  async removeAchievement(ability: AppAbility, achievementId: string) {
    const achievement = await this.prisma.achievement.findFirst({
      where: {
        AND: [
          { id: achievementId },
          accessibleBy(ability, Action.Delete).Achievement,
        ],
      },
    });

    if (!achievement) return;

    await this.prisma.achievementTracker.delete({
      where: {
        id: achievementId,
      },
    });

    await this.prisma.achievement.delete({
      where: { id: achievementId },
    });
    console.log(`Deleted achievement ${achievementId}`);
  }

  async emitUpdateAchievementData(
    achievement: Achievement,
    deleted: boolean,
    target?: User,
  ) {
    const dto: UpdateAchievementDataDto = {
      achievement: deleted
        ? { id: achievement.id }
        : await this.dtoForAchievement(achievement),
      deleted,
    };

    await this.clientService.sendProtected(
      'updateAchievementData',
      target?.id ?? achievement.id,
      dto,
      {
        id: achievement.id,
        dtoField: 'achievement',
        subject: subject('Achievement', achievement),
      },
    );
  }

  async dtoForAchievement(ach: Achievement): Promise<AchievementDto> {
    return {
      id: ach.id,
      eventId: ach.linkedEventId as string,
      requiredPoints: ach.requiredPoints,
      name: ach.name,
      description: ach.description,
      imageUrl: ach.imageUrl,
      locationType: ach.locationType as LocType,
      achievementType: ach.achievementType as AchievementType,
    };
  }

  // /** Creates an achievement tracker */
  // async createAchievementTracker(user: User, achievementId: string) {
  //   const existing = await this.prisma.achievementTracker.findFirst({
  //     where: { userId: user.id, achievementId },
  //   });

  //   if (existing) return;

  //   const progress = await this.prisma.achievementTracker.create({
  //     data: {
  //       userId: user.id,
  //       progress: 0,
  //       achievementId,
  //     },
  //   });

  //   return progress;
  // }

  // // async getAchievementTrackerById

  // async dtoForAchievementTracker(tracker: AchievementTracker): Promise<AchievementTrackerDto> {
  //   return {
  //     userId: tracker.userId,
  //     progress: tracker.progress,
  //     achievementId: tracker.achievementId,
  //     dateComplete: tracker.dateComplete?.toISOString(),
  //   };
  // }

  // /** Emits & updates an achievement tracker */
  // async emitUpdateAchievementTracker(tracker: AchievementTracker, target?: User) {
  //   const dto = await this.dtoForAchievementTracker(tracker);

  //   await this.clientService.sendProtected(
  //     'updateAchievementTrackerData',
  //     target?.id ?? tracker.userId,
  //     dto,
  //     {
  //       id: dto.achievementId,
  //       subject: 'AchievementTracker',
  //     },
  //   );
  // }
}
