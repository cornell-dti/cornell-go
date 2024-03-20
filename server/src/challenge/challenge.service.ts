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
import { ChallengeDto, UpdateChallengeDataDto } from './challenge.dto';

@Injectable()
export class ChallengeService {
  constructor(
    private log: SessionLogService,
    private readonly prisma: PrismaService,
    private eventService: EventService,
    private clientService: ClientService,
  ) {}

  /** Get challenges with prev challenges for a given user */
  async getChallengesByIdsForUser(
    user: User,
    admin: boolean,
    ids: string[],
  ): Promise<Challenge[]> {
    return await this.prisma.challenge.findMany({
      where: {
        id: { in: ids },
        linkedEvent: {
          usedIn: {
            some: admin
              ? { managers: { some: { id: user.id } } }
              : { members: { some: { id: user.id } } },
          },
        },
      },
    });
  }

  /** Get a challenge by its id */
  async getChallengeById(id: string) {
    return await this.prisma.challenge.findFirstOrThrow({ where: { id } });
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

    const curEvent = await this.prisma.eventBase.findUniqueOrThrow({
      where: { id: eventTracker.eventId },
    });

    // Ensure that the correct challenge is marked complete
    if (
      challengeId !== eventTracker.curChallengeId ||
      (groupMembers.length !== curEvent.requiredMembers &&
        curEvent.requiredMembers >= 0)
    ) {
      return false;
    }

    const prevChal = await this.prisma.prevChallenge.create({
      data: {
        userId: user.id,
        challengeId: eventTracker.curChallengeId,
        participants: {
          connect: groupMembers.map(m => ({ id: m.id })),
        },
        trackerId: eventTracker.id,
      },
    });

    const curChallenge = await this.prisma.challenge.findUniqueOrThrow({
      where: { id: eventTracker.curChallengeId },
    });

    const nextChallenge = await this.nextChallenge(curChallenge);

    await this.prisma.user.update({
      where: { id: user.id },
      data: { score: { increment: 1 } },
    });

    await this.prisma.eventTracker.update({
      where: { id: eventTracker.id },
      data: {
        score: { increment: 1 },
        curChallenge: { connect: { id: nextChallenge.id } },
        completedChallenges: { connect: { id: prevChal.id } },
      },
    });

    await this.log.logEvent(
      SessionLogEvent.COMPLETE_CHALLENGE,
      challengeId,
      user.id,
    );

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

  async setCurrentChallenge(user: User, challengeId: string) {
    const group = await this.prisma.group.findUniqueOrThrow({
      where: { id: user.groupId },
      include: { curEvent: true, members: true },
    });

    const event = group.curEvent;

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
  }

  async emitUpdateChallengeData(
    challenge: Challenge,
    deleted: boolean,
    admin?: boolean,
    client?: User,
  ) {
    const dto: UpdateChallengeDataDto = {
      challenge: deleted ? challenge.id : await this.dtoForChallenge(challenge),
      deleted,
    };

    if (client) {
      this.clientService.sendUpdate<UpdateChallengeDataDto>(
        'updateChallengeData',
        client.id,
        !!admin,
        dto,
      );
    } else {
      this.clientService.sendUpdate<UpdateChallengeDataDto>(
        'updateChallengeData',
        challenge.id,
        false,
        dto,
      );

      this.clientService.sendUpdate<UpdateChallengeDataDto>(
        'updateChallengeData',
        challenge.id,
        true,
        dto,
      );
    }
  }

  async dtoForChallenge(ch: Challenge): Promise<ChallengeDto> {
    return {
      id: ch.id,
      name: ch.name,
      location: ch.location as string,
      description: ch.description,
      points: ch.points,
      imageUrl: ch.imageUrl,
      lat: ch.latitude,
      long: ch.longitude,
      awardingRadius: ch.awardingRadius,
      closeRadius: ch.closeRadius,
      containingEventId: ch.linkedEventId!,
    };
  }

  async upsertChallengeFromDto(challenge: ChallengeDto): Promise<Challenge> {
    const assignData = {
      name: challenge.name.substring(0, 2048),
      location: challenge.location as LocationType,
      description: challenge.description.substring(0, 2048),
      points: challenge.points,
      imageUrl: challenge.imageUrl.substring(0, 2048),
      latitude: challenge.lat,
      longitude: challenge.long,
      awardingRadius: challenge.awardingRadius,
      closeRadius: challenge.closeRadius,
    };

    const challengeEntity = await this.prisma.challenge.upsert({
      where: { id: challenge.id },
      update: assignData,
      create: {
        ...assignData,
        eventIndex: -10,
        linkedEventId: challenge.containingEventId,
      },
    });

    if (challengeEntity.eventIndex === -10) {
      const maxIndexChallenge = await this.prisma.challenge.findFirst({
        where: { linkedEventId: challenge.containingEventId },
        orderBy: { eventIndex: 'desc' },
      });

      await this.prisma.challenge.update({
        where: { id: challengeEntity.id },
        data: {
          eventIndex: Math.max((maxIndexChallenge?.eventIndex ?? -1) + 1, 0),
        },
      });
    }

    return challengeEntity;
  }

  async removeChallenge(challengeId: string, accessor: User) {
    const challenge = await this.prisma.challenge.findFirstOrThrow({
      where: { id: challengeId },
      include: {
        linkedEvent: { include: { challenges: true } },
      },
    });

    const usedTrackers = await this.prisma.eventTracker.findMany({
      where: {
        curChallengeId: challengeId,
      },
    });

    const replacementChal = await this.prisma.challenge.findFirstOrThrow({
      where: { linkedEventId: challenge.linkedEventId },
      select: { id: true },
    });

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

    await this.prisma.challenge.deleteMany({
      where: {
        id: challengeId,
        linkedEvent: {
          usedIn: { some: { managers: { some: { id: accessor.id } } } },
        },
      },
    });
  }
}
