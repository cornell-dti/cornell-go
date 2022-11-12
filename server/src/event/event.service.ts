import { Injectable } from '@nestjs/common';
import {
  Challenge,
  EventBase,
  EventRewardType,
  Organization,
  User,
} from '@prisma/client';
import { UpdateEventDataEventDto } from 'src/client/update-event-data.dto';
import { ClientService } from '../client/client.service';
import { OrganizationService } from '../organization/organization.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class EventService {
  constructor(
    private clientService: ClientService,
    private orgService: OrganizationService,
    private readonly prisma: PrismaService,
  ) {}

  /** Get event by id */
  async getEventById(id: string) {
    return await this.prisma.eventBase.findUniqueOrThrow({ where: { id } });
  }

  /** Get events by ids */
  async getEventsByIds(ids: string[]): Promise<EventBase[]> {
    return await this.prisma.eventBase.findMany({ where: { id: { in: ids } } });
  }

  /** Checks if a user is allowed to see an event */
  async isAllowedEvent(user: User, eventId: string) {
    return (
      (await this.prisma.organization.count({
        where: {
          members: { some: { id: user.id } },
          allowedEvents: { some: { id: eventId } },
        },
      })) > 0
    );
  }

  /** Retrieves default event */
  async getDefaultEvent() {
    return await this.prisma.eventBase.findFirstOrThrow({
      where: { isDefault: true },
    });
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

  /** Searches events based on certain criteria */
  async searchEvents(
    offset: number,
    count: number,
    rewardTypes: EventRewardType[] | undefined = undefined,
    skippable: boolean | undefined = undefined,
    sortBy: {
      time?: 'asc' | 'desc';
      challengeCount?: 'asc' | 'desc';
    } = {},
    organizations?: Organization[],
  ) {
    const events = await this.prisma.eventBase.findMany({
      where: {
        indexable: !organizations,
        //rewardType: rewardTypes && { $in: rewardTypes },
        allowedIn: {
          some: organizations
            ? { id: { in: organizations.map(({ id }) => id) } }
            : undefined,
        },
      },
      select: { id: true },
      skip: offset,
    });

    console.log(events, offset);

    return events.map(ev => ev.id);
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
    const defaultEvId = defaultEvent[0].linkedEventId;

    const progress = await this.prisma.eventTracker.create({
      data: {
        score: 0,
        isRankedForEvent: true,
        cooldownEnd: new Date(),
        event: { connect: { id: defaultEvId } },
        curChallenge: { connect: { id: closestChalId } },
        user: { connect: { id: user.id } },
      },
    });

    this.clientService.emitInvalidateData({
      userEventData: false,
      userRewardData: false,
      winnerRewardData: false,
      groupData: false,
      challengeData: false,
      leaderboardData: true,
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
        cooldownEnd: new Date(),
        eventId: event.id,
        curChallengeId: closestChallenge.id,
        userId: user.id,
      },
    });

    this.clientService.emitInvalidateData({
      userEventData: false,
      userRewardData: false,
      winnerRewardData: false,
      groupData: false,
      challengeData: false,
      leaderboardData: true,
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

  async updateEventDataDtoForEvent(
    ev: EventBase,
  ): Promise<UpdateEventDataEventDto> {
    const fullEv = await this.prisma.eventBase.findUniqueOrThrow({
      where: { id: ev.id },
      include: {
        challenges: { select: { id: true } },
        rewards: {
          where: { userId: null },
          select: { id: true, description: true },
        },
      },
    });

    return {
      id: ev.id,
      skippingEnabled: ev.skippingEnabled,
      name: ev.name,
      description: ev.description,
      rewardType:
        ev.rewardType === EventRewardType.LIMITED_TIME
          ? 'limited_time_event'
          : 'perpetual',
      time: ev.endTime.toISOString(),
      requiredMembers: ev.requiredMembers,
      challengeIds: fullEv.challenges.map(ch => ch.id),
      rewards: fullEv.rewards.map(rw => ({
        id: rw.id,
        description: rw.description,
      })),
    };
  }

  async getEventOrganizationsForUser(
    user: User,
  ): Promise<Organization[] | undefined> {
    return (
      await this.prisma.user.findUniqueOrThrow({
        where: { id: user.id },
        include: { memberOf: true },
      })
    ).memberOf;
  }
}
