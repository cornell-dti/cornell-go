import { SessionLogService } from './../session-log/session-log.service';
import { Injectable } from '@nestjs/common';
import {
  Challenge,
  EventBase,
  TimeLimitationType,
  EventTracker,
  SessionLogEvent,
  User,
  LocationType,
  Achievement,
  AchievementTracker,
} from '@prisma/client';
import { ClientService } from '../client/client.service';
import { UserService } from '../user/user.service';
import { EventService } from '../event/event.service';
import { AchievementService } from '../achievement/achievement.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  ChallengeDto,
  UpdateChallengeDataDto,
  ChallengeLocationDto,
} from './challenge.dto';
import { AppAbility, CaslAbilityFactory } from '../casl/casl-ability.factory';
import { accessibleBy } from '@casl/prisma';
import { Action } from '../casl/action.enum';
import { subject } from '@casl/ability';
import { defaultChallengeData } from '../organization/organization.service';

@Injectable()
export class ChallengeService {
  constructor(
    private log: SessionLogService,
    private readonly prisma: PrismaService,
    private eventService: EventService,
    private achievementService: AchievementService,
    private clientService: ClientService,
    private abilityFactory: CaslAbilityFactory,
    private userService: UserService,
  ) {}

  /**
   * Calculate hint-adjusted points using the "Half-after-3" system
   * 0 hints = full points; 3 hints = exactly half points; 1-2 hints linearly reduce
   */
  private calculateHintAdjustedPoints(
    basePoints: number,
    hintsUsed: number,
  ): number {
    // Formula: P * (1 - h/6) where h is hints used
    const raw = basePoints * (1 - hintsUsed / 6.0);

    // Round to nearest 5
    const rounded = Math.round(raw / 5) * 5;

    // Ensure minimum of half points, maximum of full points
    const minAllowed = Math.floor(basePoints / 2);
    const award = Math.max(minAllowed, Math.min(rounded, basePoints));

    return award;
  }

  /** Get challenges with prev challenges for a given user */
  async getChallengesByIdsForAbility(
    ability: AppAbility,
    ids: string[],
  ): Promise<Challenge[]> {
    return await this.prisma.challenge.findMany({
      where: {
        AND: [
          { id: { in: ids } },
          accessibleBy(ability, Action.Read).Challenge,
        ],
      },
    });
  }

  /** Get a challenge by its id */
  async getChallengeById(id: string) {
    return await this.prisma.challenge.findFirst({ where: { id } });
  }

  /** Is challenge completed by user */
  async isChallengeCompletedByUser(user: User, challenge: Challenge) {
    const num = await this.prisma.prevChallenge.count({
      where: {
        userId: user.id,
        challenge: challenge,
      },
    });

    return num > 0;
  }

  /** Find first challenge */
  async getFirstChallengeForEvent(event: EventBase) {
    return await this.prisma.challenge.findFirstOrThrow({
      where: {
        eventIndex: 0,
        linkedEvent: event,
      },
    });
  }

  /** Get next challenge in a sequence of challenges */
  async nextChallenge(evTracker: EventTracker) {
    const nextChal = await this.prisma.challenge.findFirst({
      where: {
        linkedEventId: evTracker.eventId,
        completions: { none: { userId: evTracker.userId } },
      },
      orderBy: {
        eventIndex: 'asc',
      },
    });

    return nextChal;
  }

  /** Progress user through challenges, ensuring challengeId is current */
  // async completeChallenge(user: User, challengeId: string, ability: AppAbility) {
  async completeChallenge(user: User) {
    const groupMembers = await this.prisma.user.findMany({
      where: { groupId: user.groupId },
    });

    const eventTracker: EventTracker =
      await this.eventService.getCurrentEventTrackerForUser(user);

    if (!eventTracker.curChallengeId) return null;

    const alreadyDone =
      (await this.prisma.prevChallenge.count({
        where: {
          userId: user.id,
          challengeId: eventTracker.curChallengeId,
          trackerId: eventTracker.id,
        },
      })) > 0;

    // Ensure that the correct challenge is marked complete
    if (alreadyDone) {
      return null;
    }

    await this.prisma.prevChallenge.create({
      data: {
        userId: user.id,
        challengeId: eventTracker.curChallengeId,
        participants: {
          connect: groupMembers.map(m => ({ id: m.id })),
        },
        trackerId: eventTracker.id,
        hintsUsed: eventTracker.hintsUsed,
      },
    });

    const curChallenge = await this.prisma.challenge.findUniqueOrThrow({
      where: { id: eventTracker.curChallengeId },
    });

    const nextChallenge = await this.nextChallenge(eventTracker);

    const deltaScore = this.calculateHintAdjustedPoints(
      curChallenge.points,
      eventTracker.hintsUsed,
    );

    const newUser = await this.prisma.user.update({
      where: { id: user.id },
      data: { score: { increment: deltaScore } },
    });

    const newEvTracker = await this.prisma.eventTracker.update({
      where: { id: eventTracker.id },
      data: {
        score: { increment: deltaScore },
        hintsUsed: 0,
        curChallengeId: nextChallenge?.id ?? null,
      },
    });

    //Send timer start event notif to user if next challenge has a timer length
    if (nextChallenge?.timerLength) {
      await this.clientService.sendEvent(
        [`user/${user.id}`],
        'startTimerForChallenge',
        {
          challengeId: nextChallenge.id,
          timerLength: nextChallenge.timerLength,
        },
      );
    }

    await this.log.logEvent(
      SessionLogEvent.COMPLETE_CHALLENGE,
      curChallenge.id,
      user.id,
    );

    // check if the completed challenge is completing a journey
    const isJourneyCompleted =
      (await this.prisma.challenge.count({
        where: {
          linkedEvent: { id: eventTracker.eventId },
          completions: { none: { userId: user.id } },
        },
      })) === 0;

    await this.achievementService.checkAchievementProgress(
      user,
      eventTracker,
      deltaScore,
      isJourneyCompleted,
    );

    await this.eventService.emitUpdateLeaderPosition({
      playerId: newUser.id,
      newTotalScore: newUser.score,
      newEventScore: newEvTracker.score,
      eventId: newEvTracker.eventId,
    });

    const updatedChal = await this.getChallengeById(curChallenge.id);
    if (updatedChal != null) {
      await this.emitUpdateChallengeData(updatedChal, false);
      return updatedChal.name;
    }
    return null;
  }

  async getUserCompletionDate(user: User, challenge: Challenge) {
    return (
      (
        await this.prisma.prevChallenge.findFirst({
          where: { userId: user.id, challengeId: challenge.id },
        })
      )?.timestamp.toISOString() ?? ''
    );
  }

  async addChallengeToEvent(challenge: Challenge, ev: EventBase) {
    const maxIndexChallenge = await this.prisma.challenge.aggregate({
      _max: { eventIndex: true },
      where: { linkedEventId: challenge.linkedEventId },
    });

    await this.prisma.challenge.update({
      where: { id: challenge.id },
      data: {
        eventIndex: (maxIndexChallenge._max.eventIndex ?? -1) + 1,
        linkedEventId: ev.id,
      },
    });
  }

  async emitUpdateChallengeData(
    challenge: Challenge,
    deleted: boolean,
    target?: User,
  ) {
    const dto: UpdateChallengeDataDto = {
      challenge: deleted
        ? { id: challenge.id }
        : await this.dtoForChallenge(challenge),
      deleted,
    };

    await this.clientService.sendProtected(
      'updateChallengeData',
      target ?? challenge.id,
      dto,
      {
        id: challenge.id,
        dtoField: 'challenge',
        subject: 'Challenge',
        prismaStore: this.prisma.challenge,
      },
    );
  }

  async dtoForChallenge(ch: Challenge): Promise<ChallengeDto> {
    return {
      id: ch.id,
      name: ch.name,
      location: ch.location as ChallengeLocationDto,
      description: ch.description,
      points: ch.points,
      imageUrl: ch.imageUrl,
      latF: ch.latitude,
      longF: ch.longitude,
      awardingRadiusF: ch.awardingRadius,
      closeRadiusF: ch.closeRadius,
      linkedEventId: ch.linkedEventId!,
    };
  }

  async upsertChallengeFromDto(ability: AppAbility, challenge: ChallengeDto) {
    let chal = await this.prisma.challenge.findFirst({
      where: { id: challenge.id },
    });

    const canUpdateEv =
      (await this.prisma.eventBase.count({
        where: {
          AND: [
            accessibleBy(ability, Action.Update).EventBase,
            { id: challenge.linkedEventId ?? '' },
          ],
        },
      })) > 0;

    const canUpdateChal =
      (await this.prisma.challenge.count({
        where: {
          AND: [
            accessibleBy(ability, Action.Update).Challenge,
            { id: chal?.id ?? '' },
          ],
        },
      })) > 0;

    if (chal && canUpdateChal) {
      const assignData = {
        name: challenge.name?.substring(0, 2048),
        location: challenge.location as LocationType,
        points: challenge.points,
        description: challenge.description?.substring(0, 2048),
        imageUrl: challenge.imageUrl?.substring(0, 2048),
        latitude: challenge.latF,
        longitude: challenge.longF,
        awardingRadius: challenge.awardingRadiusF,
        closeRadius: challenge.closeRadiusF,
      };

      const data = await this.abilityFactory.filterInaccessible(
        chal.id,
        assignData,
        'Challenge',
        ability,
        Action.Update,
        this.prisma.challenge,
      );

      chal = await this.prisma.challenge.update({
        where: { id: chal.id },
        data,
      });
    } else if (!chal && canUpdateEv) {
      const maxIndexChallenge = await this.prisma.challenge.aggregate({
        _max: { eventIndex: true },
        where: { linkedEventId: challenge.linkedEventId },
      });
      const data = {
        name: challenge.name?.substring(0, 2048) ?? defaultChallengeData.name,
        description:
          challenge.description?.substring(0, 2048) ??
          defaultChallengeData.description,
        imageUrl:
          challenge.imageUrl?.substring(0, 2048) ??
          defaultChallengeData.imageUrl,
        location:
          (challenge.location as LocationType) ?? defaultChallengeData.location,
        points: challenge.points ?? 0,
        latitude: challenge.latF ?? defaultChallengeData.latitude,
        longitude: challenge.longF ?? defaultChallengeData.longitude,
        awardingRadius:
          challenge.awardingRadiusF ?? defaultChallengeData.awardingRadius,
        closeRadius: challenge.closeRadiusF ?? defaultChallengeData.closeRadius,
        eventIndex: (maxIndexChallenge._max.eventIndex ?? -1) + 1,
        linkedEventId: challenge.linkedEventId,
      };

      chal = await this.prisma.challenge.create({
        data,
      });

      console.log(`Created challenge ${chal.id}`);
    } else {
      return null;
    }

    await this.eventService.fixEventTrackers(chal.linkedEventId ?? undefined);

    return chal;
  }

  async removeChallenge(ability: AppAbility, challengeId: string) {
    const challenge = await this.prisma.challenge.findFirst({
      where: {
        AND: [
          { id: challengeId },
          accessibleBy(ability, Action.Delete).Challenge,
        ],
      },
    });

    if (!challenge) return false;

    await this.prisma.challenge.delete({
      where: {
        id: challengeId,
      },
    });

    await this.eventService.fixEventTrackers(
      challenge.linkedEventId ?? undefined,
    );

    console.log(`Deleted challenge ${challengeId}`);
    return true;
  }
}
