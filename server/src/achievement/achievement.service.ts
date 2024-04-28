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
import {
  defaultAchievementData,
  OrganizationService,
} from '../organization/organization.service';
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
    // private orgService: OrganizationService,
  ) {}

  /** get an achievement by its ID */
  async getAchievementFromId(id: string) {
    return await this.prisma.achievement.findFirstOrThrow({ where: { id } });
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
        // eventIndex: assignData.eventId ?? 0, // check
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
      target?.id ?? achievement.id,
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

  /** AchievementTracker functions */

  /** Creates an achievement tracker */
  async createAchievementTracker(user: User, achievementId: string) {
    const existing = await this.prisma.achievementTracker.findFirst({
      where: { userId: user.id, achievementId },
    });

    if (existing) {
      return existing;
    }

    const progress = await this.prisma.achievementTracker.create({
      data: {
        userId: user.id,
        progress: 0,
        achievementId,
      },
    });

    return progress;
  }

  async getAchievementTrackerByAchievementId(
    user: User,
    achievementId: string,
  ) {
    return await this.prisma.achievementTracker.findFirst({
      where: { userId: user.id, achievementId },
    });
  }

  async dtoForAchievementTracker(
    tracker: AchievementTracker,
  ): Promise<AchievementTrackerDto> {
    const achievement = await this.getAchievementFromId(tracker.achievementId);
    return {
      userId: tracker.userId,
      progress: tracker.progress,
      achievementId: tracker.achievementId,
      dateComplete: tracker.dateComplete?.toISOString(),
    };
  }

  /** Emits & updates an achievement tracker */
  async emitUpdateAchievementTracker(
    tracker: AchievementTracker,
    target?: User,
  ) {
    const dto = await this.dtoForAchievementTracker(tracker);

    await this.clientService.sendProtected(
      'updateAchievementTrackerData',
      target?.id ?? tracker.userId,
      dto,
      {
        id: dto.achievementId,
        subject: 'AchievementTracker',
        prismaStore: this.prisma.achievementTracker,
      },
    );
  }

  /** checks for all achievements associated with a user for a given completed challenge. */
  async checkAchievementProgress(
    user: User,
    challengeId: string,
    isJourney: boolean,
  ) {
    // find challenge corresponding to challengeId
    const curChallenge = await this.prisma.challenge.findUniqueOrThrow({
      where: { id: challengeId },
    });

    const ability = await this.abilityFactory.createForUser(user);

    // find all achievements associated with the challenge that are accessible
    // by user and have incomplete trackers; joins tracker to resulting query
    const achs = await this.prisma.achievement.findMany({
      where: {
        OR: [
          { linkedEventId: challengeId }, // achievements linked to the specific event of the challenge
          { linkedEventId: null }, // achievements not linked to any specific event
        ],
        AND: [
          accessibleBy(ability, Action.Read).Achievement,
          {locationType: curChallenge.location},
        ],
      },
      include: {
        trackers: {
          where: {
            userId: user.id,
            dateComplete: null, // trackers for achievements that are not complete
          },
        },
      },
    });

    // iterate through each achievement and update progress
    for (const achId in achs) {
      // find tracker associated with ach
      let tracker = await this.prisma.achievementTracker.findFirst({
        where: {
          userId: user.id,
          achievementId: achId,
        },
      });

      // if tracker doesn't exist, create a new tracker associated with ach
      if (tracker == null) {
        tracker = await this.createAchievementTracker(user, achId);
      }

      // update tracker with new progress; complete tracker if necessary
      const ach = await this.getAchievementFromId(achId);

      const journeyOrChalAchShouldProgress =
        ach.achievementType ===
          AchievementTypeDto.TOTAL_CHALLENGES_OR_JOURNEYS ||
        (isJourney &&
          ach.achievementType === AchievementTypeDto.TOTAL_JOURNEYS) ||
        (!isJourney &&
          ach.achievementType === AchievementTypeDto.TOTAL_CHALLENGES);

          
      if (ach.achievementType === AchievementTypeDto.TOTAL_POINTS) {
        tracker.progress += curChallenge.points;
        if (tracker.progress >= ach.requiredPoints) {
          // ach is newly completed; update tracker with completion date
          tracker.dateComplete = new Date();
        }
      } else if (journeyOrChalAchShouldProgress) {
        tracker.progress += 1;
        if (tracker.progress >= ach.requiredPoints) {
          tracker.dateComplete = new Date();
        }
      }

      await this.prisma.achievementTracker.update({
        where: { id: tracker.id },
        data: {
          progress: tracker.progress,
          dateComplete: tracker.dateComplete,
        },
      });
    }
  }
}
