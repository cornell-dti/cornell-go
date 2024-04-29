import { SessionLogService } from './../session-log/session-log.service';
import { Injectable } from '@nestjs/common';
import {
  $Enums,
  Achievement,
  AchievementType,
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
  AchievementTypeDto,
  AchievementDto,
  AchievementTrackerDto,
  UpdateAchievementDataDto,
} from './achievement.dto';
import { ChallengeLocationDto } from '../challenge/challenge.dto';

@Injectable()
export class AchievementService {
  constructor(
    private readonly prisma: PrismaService,
    private clientService: ClientService,
    private abilityFactory: CaslAbilityFactory,
  ) {}

  /** get an achievement by its ID */
  async getAchievementFromId(id: string) {
    return await this.prisma.achievement.findFirst({ where: { id } });
  }

  /** get list of achievements by IDs, based on ability */
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

    const canUpdateOrg =
      (await this.prisma.organization.count({
        where: {
          AND: [
            accessibleBy(ability, Action.Update).Organization,
            { id: achievement.initialOrganizationId ?? '' },
          ],
        },
      })) > 0;

    const canUpdateEv =
      (await this.prisma.eventBase.count({
        where: {
          AND: [
            accessibleBy(ability, Action.Update).EventBase,
            { id: achievement.eventId ?? '' },
          ],
        },
      })) > 0;

    const canUpdateAch =
      (await this.prisma.achievement.count({
        where: {
          AND: [
            accessibleBy(ability, Action.Update).Achievement,
            { id: ach?.id ?? '' },
          ],
        },
      })) > 0;

    if (ach && canUpdateAch) {
      const assignData = {
        requiredPoints: achievement.requiredPoints,
        name: achievement.name?.substring(0, 2048),
        description: achievement.description?.substring(0, 2048),
        imageUrl: achievement.imageUrl?.substring(0, 2048),
        locationType: achievement.locationType as LocationType,
        achievementType: achievement.achievementType as AchievementTypeDto,
        linkedEventId:
          achievement.eventId && achievement.eventId !== '' && canUpdateEv
            ? achievement.eventId
            : null,
      };
      const data = await this.abilityFactory.filterInaccessible(
        ach.id,
        assignData,
        'Achievement',
        ability,
        Action.Update,
        this.prisma.achievement,
      );

      ach = await this.prisma.achievement.update({
        where: { id: ach.id },
        data,
      });
    } else if (!ach && canUpdateOrg) {
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
        achievementType: achievement.achievementType as AchievementTypeDto,
        requiredPoints: achievement.requiredPoints ?? 1,
        organizations: { connect: { id: achievement.initialOrganizationId } },
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

  /** remove achievement by ID; return removal status */
  async removeAchievement(ability: AppAbility, achievementId: string) {
    const achievement = await this.prisma.achievement.findFirst({
      where: {
        AND: [
          { id: achievementId },
          accessibleBy(ability, Action.Delete).Achievement,
        ],
      },
    });

    if (achievement) {
      await this.prisma.achievement.delete({
        where: { id: achievementId },
      });
      console.log(`Deleted achievement ${achievementId}`);
      return true;
    }
    return false;
  }

  /** emit & update data for an achievement */
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
      target ?? achievement.id,
      dto,
      {
        id: achievement.id,
        subject: 'Achievement',
        dtoField: 'achievement',
        prismaStore: this.prisma.achievement,
      },
    );
  }

  /**
   * Converts an achievement from the database to a DTO
   * @param ach event to get DTO for
   * @returns an AchievementDTO for the event
   */
  async dtoForAchievement(ach: Achievement): Promise<AchievementDto> {
    return {
      id: ach.id,
      eventId: ach.linkedEventId as string,
      requiredPoints: ach.requiredPoints,
      name: ach.name,
      description: ach.description,
      imageUrl: ach.imageUrl,
      locationType: ach.locationType as ChallengeLocationDto,
      achievementType: ach.achievementType as AchievementTypeDto,
    };
  }
}
