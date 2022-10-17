import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { UserService } from '../user/user.service';
import { ChallengeService } from 'src/challenge/challenge.service';
import { ClientService } from '../client/client.service';
import {
  EventBase,
  EventRewardType,
  EventTracker,
  PrismaClient,
  RestrictionGroup,
  User,
} from '@prisma/client';
import { UpdateEventDataEventDto } from 'src/client/update-event-data.dto';

@Injectable()
export class EventService {
  constructor(
    private userService: UserService,
    private clientService: ClientService,
    private readonly prisma: PrismaClient,
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
    if (user.restrictedById) {
      const restriction = await this.prisma.restrictionGroup.findFirstOrThrow({
        where: { id: user.restrictedById },
        include: { allowedEvents: true },
      });
      const hasEventRestrictions = restriction.allowedEvents.length > 0;
      if (hasEventRestrictions) {
        return restriction.allowedEvents.some(e => e.id === eventId);
      }
    }
    return true;
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
    restriction?: RestrictionGroup,
  ) {
    const events = await this.prisma.eventBase.findMany({
      where: {
        indexable: !restriction,
        //rewardType: rewardTypes && { $in: rewardTypes },
        allowedIn: { some: restriction },
      },
      select: { id: true },
      skip: offset,
    });

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
    await this.getDefaultEvent();

    lat = +lat;
    long = +long;

    const defaultEvent: { 'ev.id': string; 'chal.id': string }[] = await this
      .prisma.$queryRaw`
      select * from EventBase ev 
      left join Challenge chal 
      on ev.id = chal.linkedEventId and chal.isDefault = true
      order by ((chal.latitude - ${lat})^2 + (chal.longitude - ${long})^2) desc
    `;

    if (defaultEvent.length === 0) throw 'Cannot find closest challenge!';

    const closestChalId = defaultEvent[0]['chal.id'];
    const defaultEvId = defaultEvent[0]['ev.id'];

    const progress = await this.prisma.eventTracker.create({
      data: {
        score: 0,
        isRankedForEvent: true,
        cooldownEnd: new Date(),
        eventId: defaultEvId,
        curChallengeId: closestChalId,
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

  async getDefaultEvent() {
    try {
      return await this.prisma.eventBase.findFirstOrThrow({
        where: {
          isDefault: true,
        },
      });
    } catch {
      return await this.makeDefaultEvent();
    }
  }

  async createEventTracker(user: User, event: EventBase) {
    const closestChallenge = await this.prisma.challenge.findFirstOrThrow({
      where: {
        eventIndex: 0,
        linkedEvent: event,
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
        user,
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

  async makeDefaultEvent() {
    return await this.prisma.eventBase.create({
      data: {
        name: 'Default Event',
        description: 'Default Event',
        requiredMembers: 1,
        minimumScore: 1,
        skippingEnabled: true,
        isDefault: true,
        rewardType: EventRewardType.PERPETUAL,
        indexable: false,
        endTime: new Date('2060'),
        challenges: {
          create: {
            eventIndex: 0,
            name: 'New challenge',
            description: 'McGraw Tower',
            imageUrl:
              'https://upload.wikimedia.org/wikipedia/commons/5/5f/CentralAvenueCornell2.jpg',
            latitude: 42.44755580740012,
            longitude: -76.48504614830019,
            awardingRadius: 50,
            closeRadius: 100,
          },
        },
      },
    });
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

  async getEventRestrictionForUser(
    user: User,
  ): Promise<RestrictionGroup | undefined> {
    const restriction = await user.restrictedById;
    if (!restriction) return undefined;

    const restrictions = await this.prisma.restrictionGroup.findMany({
      where: { id: restriction, allowedEvents: { some: {} } },
    });

    return restrictions.length === 0 ? undefined : restrictions[0];
  }
}
