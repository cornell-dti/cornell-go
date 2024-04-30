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
  EventTracker,
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
    if (ach) this.createAchievementTrackers(undefined, ach);
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

  async getAchievementTrackersForUser(user: User, achievementIds?: string[]) {
    return await this.prisma.achievementTracker.findMany({
      where: {
        userId: user.id,
        achievementId: achievementIds ? { in: achievementIds } : undefined,
      },
    });
  }

  async dtoForAchievementTracker(
    tracker: AchievementTracker,
  ): Promise<AchievementTrackerDto> {
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
      target ?? tracker.id,
      dto,
      {
        id: tracker.id,
        subject: 'AchievementTracker',
        prismaStore: this.prisma.achievementTracker,
      },
    );
  }

  /** checks for all achievements associated with a user for a given completed challenge. */
  async checkAchievementProgress(
    user: User,
    evTracker: EventTracker,
    pointsAdded: number,
  ) {
    const ability = this.abilityFactory.createForUser(user);

    const isJourney = await this.prisma.challenge.count({
      where: { linkedEventId: evTracker.eventId },
    });

    const locations = (
      await this.prisma.challenge.findMany({
        distinct: ['location'],
        select: { location: true },
      })
    ).map(l => l.location);

    const uncompletedAchs = await this.prisma.achievement.findMany({
      where: {
        AND: [
          accessibleBy(ability, Action.Read).Achievement,
          {
            // must either be for all events or for this one
            OR: [{ linkedEventId: null }, { linkedEventId: evTracker.eventId }],
          },
          {
            // must either be any location of one of the ones here
            OR: [
              { locationType: { in: locations } },
              { locationType: LocationType.ANY },
            ],
          },
          {
            // must either be both challenge + journey achievement
            // total points achievement
            // or journey/challenge achievement depending on what was completed
            OR: [
              { achievementType: AchievementType.TOTAL_CHALLENGES_OR_JOURNEYS },
              { achievementType: AchievementType.TOTAL_POINTS },
              {
                achievementType: isJourney
                  ? AchievementType.TOTAL_JOURNEYS
                  : AchievementType.TOTAL_CHALLENGES,
              },
            ],
          },
          {
            // Only find non-completed achievements
            OR: [
              {
                trackers: {
                  some: {
                    userId: user.id,
                    dateComplete: null,
                  },
                },
              },
              { trackers: { none: { userId: user.id } } },
            ],
          },
        ],
      },
      include: {
        trackers: {
          where: {
            userId: user.id,
          },
        },
      },
    });

    for (const ach of uncompletedAchs) {
      let achTracker = ach.trackers[0];

      // In case the above completion check fails
      if (achTracker.progress < ach.requiredPoints) {
        const deltaProgress =
          ach.achievementType === AchievementType.TOTAL_POINTS
            ? pointsAdded
            : 1;

        achTracker = await this.prisma.achievementTracker.update({
          where: { id: achTracker.id },
          data: {
            progress: { increment: deltaProgress },
            dateComplete:
              achTracker.progress + deltaProgress >= ach.requiredPoints
                ? new Date()
                : null,
          },
        });

        if (achTracker.progress > ach.requiredPoints) {
          achTracker = await this.prisma.achievementTracker.update({
            where: { id: achTracker.id },
            data: {
              progress: { set: ach.requiredPoints },
            },
          });
        }

        await this.clientService.subscribe(user, achTracker.id);
        await this.emitUpdateAchievementTracker(achTracker);
      }
    }
  }

  async createAchievementTrackers(user?: User, achievement?: Achievement) {
    if (user) {
      const ability = this.abilityFactory.createForUser(user);

      const achsWithoutTrackers = await this.prisma.achievement.findMany({
        where: {
          AND: [
            { id: achievement?.id },
            accessibleBy(ability).Achievement,
            { trackers: { none: { userId: user.id } } },
          ],
        },
      });

      await this.prisma.achievementTracker.createMany({
        data: achsWithoutTrackers.map(ach => ({
          userId: user.id,
          progress: 0,
          achievementId: ach.id,
        })),
      });
    } else if (achievement) {
      const usersWithoutTrackers = await this.prisma.user.findMany({
        where: {
          memberOf: {
            some: { achievements: { some: { id: achievement.id } } },
          },
          achievementTrackers: {
            none: { achievementId: achievement.id },
          },
        },
      });

      await this.prisma.achievementTracker.createMany({
        data: usersWithoutTrackers.map(usr => ({
          userId: usr.id,
          progress: 0,
          achievementId: achievement.id,
        })),
      });
    } else {
      throw 'Cannot create all possible achievement trackers in one call!';
    }
  }
}
