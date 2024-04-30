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
} from '@prisma/client';
import { ClientService } from '../client/client.service';
import { EventService } from '../event/event.service';
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
    private clientService: ClientService,
    private abilityFactory: CaslAbilityFactory,
  ) {}

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
  async nextChallenge(chal: Challenge) {
    return (
      (await this.prisma.challenge.findFirst({
        where: {
          eventIndex: chal.eventIndex + 1,
          linkedEventId: chal.linkedEventId,
        },
      })) ?? chal
    );
  }

  /** Progress user through challenges, ensuring challengeId is current */
  async completeChallenge(user: User, challengeId: string) {
    const groupMembers = await this.prisma.user.findMany({
      where: { groupId: user.groupId },
    });

    const eventTracker: EventTracker =
      await this.eventService.getCurrentEventTrackerForUser(user);

    const alreadyDone =
      (await this.prisma.prevChallenge.count({
        where: {
          userId: user.id,
          challengeId: eventTracker.curChallengeId,
          trackerId: eventTracker.id,
        },
      })) > 0;

    // Ensure that the correct challenge is marked complete
    if (challengeId !== eventTracker.curChallengeId || alreadyDone) {
      return false;
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

    const nextChallenge = await this.nextChallenge(curChallenge);

    const totalScore = curChallenge.points - 25 * eventTracker.hintsUsed;

    const newUser = await this.prisma.user.update({
      where: { id: user.id },
      data: { score: { increment: totalScore } },
    });

    const newEvTracker = await this.prisma.eventTracker.update({
      where: { id: eventTracker.id },
      data: {
        score: { increment: totalScore },
        hintsUsed: 0,
        curChallenge: { connect: { id: nextChallenge.id } },
      },
    });

    await this.log.logEvent(
      SessionLogEvent.COMPLETE_CHALLENGE,
      challengeId,
      user.id,
    );

    await this.eventService.emitUpdateLeaderPosition({
      playerId: newUser.id,
      newTotalScore: newUser.score,
      newEventScore: newEvTracker.score,
      eventId: newEvTracker.eventId,
    });

    const updatedChal = await this.getChallengeById(challengeId);
    if (updatedChal != null)
      await this.emitUpdateChallengeData(updatedChal, false);

    return true;
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

  // Disabled for now
  /*
  async setCurrentChallenge(user: User, challengeId: string) {
    const group = await this.prisma.group.findUniqueOrThrow({
      where: { id: user.groupId },
      include: { curEvent: true, members: true },
    });

    const isChallengeValid = await this.eventService.isChallengeInEvent(
      challengeId,
      group.curEventId,
    );

    if (!isChallengeValid) {
      return false;
    }

    const eventTracker: EventTracker =
      await this.eventService.getCurrentEventTrackerForUser(user);

    const challenge = await this.getChallengeById(challengeId);

    if (!challenge) return false;

    await this.prisma.eventTracker.update({
      where: { id: eventTracker.id },
      data: {
        curChallengeId: challenge.id,
      },
    });

    await this.log.logEvent(
      SessionLogEvent.SET_CHALLENGE,
      challengeId,
      user.id,
    );

    return true;
  }*/

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
      include: {
        linkedEvent: { include: { challenges: true } },
      },
    });

    if (!challenge) return false;

    // checks for any eventTracker entries that reference the challenge
    const usedTrackers = await this.prisma.eventTracker.findMany({
      where: {
        curChallengeId: challengeId,
      },
    });

    // finds replacement challenge within the same event as the one being deleted
    const replacementChal = await this.prisma.challenge.findFirstOrThrow({
      where: { linkedEventId: challenge.linkedEventId },
      select: { id: true },
    });

    // updates all affected trackers to reference the replacement challenge
    for (const tracker of usedTrackers) {
      await this.prisma.eventTracker.update({
        where: { id: tracker.id },
        data: {
          curChallenge: {
            connect: { id: replacementChal.id },
          },
        },
      });
    }

    await this.prisma.challenge.delete({
      where: {
        id: challengeId,
      },
    });

    console.log(`Deleted challenge ${challengeId}`);
    return true;
  }
}
