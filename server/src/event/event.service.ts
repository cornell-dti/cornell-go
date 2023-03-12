import { Injectable } from '@nestjs/common';
import {
  Challenge,
  EventBase,
  EventRewardType,
  EventTracker,
  User,
} from '@prisma/client';
import { LeaderDto, UpdateLeaderDataDto } from 'src/challenge/challenge.dto';
import { v4 } from 'uuid';
import { ClientService } from '../client/client.service';
import {
  defaultChallengeData,
  OrganizationService,
} from '../organization/organization.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  EventDto,
  EventTrackerDto,
  UpdateEventDataDto,
  RequestRecommendedEventsDto,
} from './event.dto';

@Injectable()
export class EventService {
  constructor(
    private clientService: ClientService,
    private orgService: OrganizationService,
    private readonly prisma: PrismaService,
  ) {}

  /** Get event by id */
  async getEventById(id: string | null) {
    if (!id) throw 'Found null event id! Possible null linked event.';
    return await this.prisma.eventBase.findUniqueOrThrow({ where: { id } });
  }

  /** Get event with orgs */
  async getEventWithOrgs(id: string) {
    return await this.prisma.eventBase.findUniqueOrThrow({
      where: { id },
      include: { usedIn: true },
    });
  }

  /** Get events by ids */
  async getEventsByIdsForUser(
    ids: string[],
    admin: boolean,
    user: User,
  ): Promise<EventBase[]> {
    return await this.prisma.eventBase.findMany({
      where: {
        id: { in: ids },
        indexable: admin ? undefined : true,
        usedIn: {
          some: admin
            ? { managers: { some: { id: user.id } } }
            : { members: { some: { id: user.id } } },
        },
      },
    });
  }

  /** Checks if a user is allowed to see an event */
  async isAllowedEvent(user: User, eventId: string) {
    return (
      (await this.prisma.organization.count({
        where: {
          members: { some: { id: user.id } },
          events: { some: { id: eventId } },
        },
      })) > 0
    );
  }

  /** Get top players for event */
  async getTopTrackersForEvent(eventId: string, offset: number, count: number) {
    return await this.prisma.eventTracker.findMany({
      where: {
        eventId: eventId,
        isRankedForEvent: true,
        user: {
          isRanked: true,
        },
      },
      skip: offset,
      take: count,
      orderBy: { score: 'desc' },
      include: {
        user: {
          select: { id: true, username: true },
        },
      },
    });
  }

  /** Verifies that a challenge is in an event */
  async isChallengeInEvent(challengeId: string, eventId: string) {
    return (
      (await this.prisma.eventBase.count({
        where: {
          id: eventId,
          challenges: {
            some: {
              id: challengeId,
            },
          },
        },
      })) > 0
    );
  }

  /** Creates an event tracker with the closest challenge as the current one */
  async createDefaultEventTracker(user: User, lat: number, long: number) {
    // gets default event of user's first organization
    // we let users choose which org they want the default event for
    const defEv = await this.orgService.getDefaultEvent(
      (
        await this.prisma.user.findUniqueOrThrow({
          where: { id: user.id },
          include: { memberOf: true },
        })
      ).memberOf[0],
    );

    lat = +lat;
    long = +long;

    const defaultEvent: Challenge[] = await this.prisma.$queryRaw`
      select * from "EventBase" ev 
      inner join "Challenge" chal 
      on ev.id = chal."linkedEventId" and ev."id" = ${defEv.id}
      order by ((chal."latitude" - ${lat})^2 + (chal."longitude" - ${long})^2) desc
    `;

    if (defaultEvent.length === 0) throw 'Cannot find closest challenge!';

    const closestChalId = defaultEvent[0].id;
    const defaultEvId = defaultEvent[0].linkedEventId!;

    const progress = await this.prisma.eventTracker.create({
      data: {
        score: 0,
        isRankedForEvent: true,
        event: { connect: { id: defaultEvId } },
        curChallenge: { connect: { id: closestChalId } },
        user: { connect: { id: user.id } },
      },
    });

    return progress;
  }

  async createEventTracker(user: User, event: EventBase) {
    const existing = await this.prisma.eventTracker.findFirst({
      where: { userId: user.id, eventId: event.id },
    });

    if (existing) {
      return existing;
    }

    const closestChallenge = await this.prisma.challenge.findFirstOrThrow({
      where: {
        eventIndex: 0,
        linkedEvent: { id: event.id },
      },
    });

    const progress = await this.prisma.eventTracker.create({
      data: {
        score: 0,
        isRankedForEvent: true,
        eventId: event.id,
        curChallengeId: closestChallenge.id,
        userId: user.id,
      },
    });

    return progress;
  }

  /** Get a player's event trackers by event id */
  async getEventTrackersByEventId(user: User, eventIds: string[]) {
    return await this.prisma.eventTracker.findMany({
      where: {
        userId: user.id,
        eventId: { in: eventIds },
      },
      include: {
        completedChallenges: {
          include: {
            challenge: {
              select: { id: true },
            },
          },
        },
      },
    });
  }

  /** Gets a player's event tracker based on group */
  async getCurrentEventTrackerForUser(user: User) {
    const evTracker = await this.prisma.eventTracker.findFirst({
      where: {
        id: user.id,
        event: {
          activeGroups: { some: { id: user.groupId } },
        },
      },
      include: { event: true },
    });

    if (!evTracker) {
      const ev = await this.prisma.eventBase.findFirstOrThrow({
        where: {
          activeGroups: { some: { id: user.groupId } },
        },
      });
      return await this.createEventTracker(user, ev);
    }
    return evTracker;
  }

  async getEventsForUser(user: User) {
    return await this.prisma.eventBase.findMany({
      where: { usedIn: { some: { members: { some: { id: user.id } } } } },
    });
  }

  async getRecommendedEventsForUser(
    user: User,
    data: RequestRecommendedEventsDto,
  ) {
    const evs: EventBase[] = await this.prisma.$queryRaw`
      select * from "EventBase" ev 
      where ev."id" in (select e."A" from "_eventOrgs" e inner join "_player" p on e."B" = p."A" and ${
        user.id
      } = p."B")
      order by ((ev."latitude" - ${data.latitude})^2 + (ev."longitude" - ${
      data.longitude
    })^2)
      fetch first ${data.count ?? 4} rows only
    `;
    return evs;
  }

  /** Get the top N users by score */
  async getTopPlayers(firstIndex: number, count: number) {
    return await this.prisma.user.findMany({
      where: { isRanked: true },
      orderBy: { score: 'desc' },
      skip: firstIndex,
      take: count,
    });
  }

  async dtoForEvent(ev: EventBase): Promise<EventDto> {
    const chals = await this.prisma.challenge.findMany({
      where: { linkedEventId: ev.id },
      select: { id: true, eventIndex: true, latitude: true, longitude: true },
    });

    const rws = await this.prisma.eventReward.findMany({
      where: { eventId: ev.id },
      select: { id: true, eventIndex: true },
    });

    const sortedChals = chals.sort((a, b) => a.eventIndex - b.eventIndex);

    return {
      id: ev.id,
      name: ev.name,
      description: ev.description,
      rewardType:
        ev.rewardType == EventRewardType.LIMITED_TIME
          ? 'limited_time'
          : 'perpetual',
      endTime: ev.endTime.toUTCString(),
      requiredMembers: ev.requiredMembers,
      indexable: ev.indexable,
      challengeIds: sortedChals.map(c => c.id),
      rewardIds: rws
        .sort((a, b) => a.eventIndex - b.eventIndex)
        .map(({ id }) => id),
      minimumScore: ev.minimumScore,
      defaultChallengeId: ev.defaultChallengeId,
      latitude: ev.latitude,
      longitude: ev.longitude,
    };
  }

  async dtoForEventTracker(tracker: EventTracker): Promise<EventTrackerDto> {
    const completedChallenges = await this.prisma.challenge.findMany({
      where: { completions: { some: { userId: tracker.userId } } },
      include: { completions: { where: { userId: tracker.userId } } },
    });

    return {
      eventId: tracker.eventId,
      isRanked: tracker.isRankedForEvent,
      curChallengeId: tracker.curChallengeId,
      prevChallengeIds: completedChallenges.map(pc => pc.id),
      prevChallengeDates: completedChallenges.map(pc =>
        pc.completions[0].timestamp.toUTCString(),
      ),
    };
  }

  async emitUpdateEventTracker(tracker: EventTracker) {
    const dto = await this.dtoForEventTracker(tracker);
    this.clientService.sendUpdate(
      'updateEventTrackerData',
      tracker.userId,
      false,
      dto,
    );
  }

  async emitUpdateEventData(
    ev: EventBase,
    deleted: boolean,
    admin?: boolean,
    client?: User,
  ) {
    const dto: UpdateEventDataDto = {
      event: deleted ? ev.id : await this.dtoForEvent(ev),
      deleted,
    };

    if (client) {
      this.clientService.sendUpdate<UpdateEventDataDto>(
        'updateEventData',
        client.id,
        !!admin,
        dto,
      );
    } else {
      this.clientService.sendUpdate<UpdateEventDataDto>(
        'updateEventData',
        ev.id,
        false,
        dto,
      );

      this.clientService.sendUpdate<UpdateEventDataDto>(
        'updateEventData',
        ev.id,
        true,
        dto,
      );
    }
  }

  async emitUpdateLeaderData(
    offset: number,
    count: number,
    event: EventBase | null,
    client: User,
  ) {
    let leaderData: LeaderDto[] = [];
    if (event) {
      const trackers = await this.getTopTrackersForEvent(
        event.id,
        offset,
        count,
      );

      leaderData = trackers.map(tracker => ({
        userId: tracker.id,
        username: tracker.user.username,
        score: tracker.score,
      }));
    } else {
      const players = await this.getTopPlayers(offset, count);

      leaderData = players.map(p => ({
        userId: p.id,
        username: p.username,
        score: p.score,
      }));
    }

    const dto: UpdateLeaderDataDto = {
      eventId: event?.id ?? '',
      offset,
      users: leaderData,
    };

    this.clientService.sendUpdate('updateLeaderData', client.id, false, dto);
  }

  async hasAdminRights(
    ev: EventBase | { id: string },
    user: User | { id: string },
  ) {
    return !!(await this.prisma.organization.findFirst({
      select: { id: true },
      where: {
        events: { some: { id: ev.id } },
        managers: { some: { id: user.id } },
      },
    }));
  }

  async updateLongitudeLatitude(eventId: string) {
    const ev = await this.prisma.eventBase.findFirst({
      where: { id: eventId },
      select: { challenges: true },
    });
    const firstChalId = ev?.challenges.sort(
      (a, b) => a.eventIndex - b.eventIndex,
    )[0].id;
    const chal = await this.prisma.challenge.findFirst({
      where: { id: firstChalId },
      select: { latitude: true, longitude: true },
    });
    const updatedEv = await this.prisma.eventBase.update({
      where: {
        id: eventId,
      },
      data: {
        longitude: chal?.longitude,
        latitude: chal?.latitude,
      },
    });
    return updatedEv;
  }

  async upsertEventFromDto(event: EventDto) {
    const firstChal = await this.prisma.challenge.findFirst({
      where: { id: event.challengeIds[0] },
      select: { latitude: true, longitude: true },
    });

    const assignData = {
      requiredMembers: event.requiredMembers,
      name: event.name.substring(0, 2048),
      description: event.description.substring(0, 2048),
      rewardType:
        event.rewardType === 'limited_time'
          ? EventRewardType.LIMITED_TIME
          : EventRewardType.PERPETUAL,
      endTime: new Date(event.endTime),
      indexable: event.indexable,
      minimumScore: event.minimumScore,
      latitude: firstChal?.latitude ?? 0,
      longitude: firstChal?.longitude ?? 0,
    };

    const eventEntity = await this.prisma.eventBase.upsert({
      where: { id: event.id },
      create: {
        ...assignData,
        usedIn: {
          connect: { id: event.initialOrganizationId ?? '' },
        },
        defaultChallenge: {
          create: {
            ...defaultChallengeData,
          },
        },
      },
      update: {
        ...assignData,
        defaultChallengeId: event.defaultChallengeId,
        challenges: {
          set: event.challengeIds
            .map(id => ({ id }))
            .concat({ id: event.defaultChallengeId }),
        },
        rewards: {
          set: event.rewardIds.map(id => ({ id })),
        },
      },
    });

    const eventEntity2 = await this.prisma.eventBase.update({
      where: { id: eventEntity.id },
      data: { challenges: { connect: { id: eventEntity.defaultChallengeId } } },
    });

    let eventIndexChal = 0;
    for (const id of event.challengeIds) {
      await this.prisma.challenge.update({
        where: { id },
        data: {
          eventIndex: eventIndexChal,
        },
      });

      ++eventIndexChal;
    }

    let eventIndexReward = 0;
    for (const id of event.rewardIds) {
      await this.prisma.eventReward.update({
        where: { id },
        data: {
          eventIndex: eventIndexReward,
        },
      });

      ++eventIndexReward;
    }

    return eventEntity2;
  }

  async removeEvent(eventId: string, accessor: User) {
    return await this.prisma.eventBase.deleteMany({
      where: {
        id: eventId,
        usedIn: { some: { managers: { some: { id: accessor.id } } } },
      },
    });
  }
}
