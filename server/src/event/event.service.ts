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
      const restriction = this.prisma.restrictionGroup.findFirst({
        where: { id: user.restrictedById },
      });
      const hasEventRestrictions =
        (await restriction.allowedEvents.loadCount()) > 0;
      if (hasEventRestrictions) {
        return (
          (await this.eventsRepository.count({
            allowedIn: restriction,
            id: eventId,
          })) > 0
        );
      }
    }
    return true;
  }

  /** Get top players for event */
  async getTopTrackersForEvent(
    eventId: string,
    offset: number,
    count: number,
  ): Promise<EventTracker[]> {
    return await this.eventTrackerRepository.find(
      {
        event: eventId,
        isPlayerRanked: true,
        user: {
          isRanked: true,
        },
      },
      { offset, limit: count, orderBy: { eventScore: 'desc' } },
    );
  }

  /** Searches events based on certain criteria */
  async searchEvents(
    offset: number,
    count: number,
    rewardTypes: EventRewardType[] | undefined = undefined,
    skippable: boolean | undefined = undefined,
    sortBy: {
      time?: 'ASC' | 'DESC';
      challengeCount?: 'ASC' | 'DESC';
    } = {},
    restriction?: RestrictionGroup,
  ) {
    const events = await this.eventsRepository.find(
      {
        indexable: !restriction,
        //rewardType: rewardTypes && { $in: rewardTypes },
        allowedIn: restriction,
      },
      {
        offset,
        //limit: count,
      },
    );

    return events.map(ev => ev.id);
  }

  /** Verifies that a challenge is in an event */
  async isChallengeInEvent(challengeId: string, eventId: string) {
    const resultCount = await this.eventsRepository
      .createQueryBuilder()
      .join('challenges', 'challenge')
      .where({ id: eventId, 'challenge.id': challengeId })
      .getCount();

    return resultCount > 0;
  }

  /** Creates an event tracker with the closest challenge as the current one */
  async createDefaultEventTracker(user: User, lat: number, long: number) {
    await this.getDefaultEvent();

    const defaultEvent = await this.eventsRepository
      .createQueryBuilder('ev')
      .select(['ev.*'])
      .where({ isDefault: true })
      .joinAndSelect('ev.challenges', 'chal')
      .orderBy({
        [`((chal.latitude - (${+lat}))^2 + (chal.longitude - (${+long}))^2)`]:
          'asc',
      })
      .getSingleResult();

    const closestChallenge = defaultEvent?.challenges[0];

    if (!closestChallenge) throw 'Cannot find closest challenge!';

    const progress: EventTracker = this.eventTrackerRepository.create({
      eventScore: 0,
      isPlayerRanked: true,
      cooldownMinimum: new Date(),
      event: defaultEvent,
      currentChallenge: closestChallenge,
      completed: [],
      user,
    });

    this.clientService.emitInvalidateData({
      userEventData: false,
      userRewardData: false,
      winnerRewardData: false,
      groupData: false,
      challengeData: false,
      leaderboardData: true,
    });

    await this.eventTrackerRepository.persistAndFlush(progress);

    return progress;
  }

  async getDefaultEvent() {
    try {
      return await this.eventsRepository.findOneOrFail({
        isDefault: true,
      });
    } catch {
      return await this.makeDefaultEvent();
    }
  }

  async createEventTracker(user: User, event: EventBase) {
    const closestChallenge = await this.challengeRepository.findOneOrFail({
      eventIndex: 0,
      linkedEvent: event,
    });

    const progress: EventTracker = this.eventTrackerRepository.create({
      eventScore: 0,
      isPlayerRanked: true,
      cooldownMinimum: new Date(),
      event: event,
      currentChallenge: closestChallenge,
      completed: [],
      user,
    });

    await this.eventTrackerRepository.persistAndFlush(progress);

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
    return await this.eventTrackerRepository.find({
      user,
      event: { id: eventIds },
    });
  }

  /** Gets a player's event tracker based on group */
  async getCurrentEventTrackerForUser(user: User) {
    const group = await user.group.load();

    const evTracker = await this.eventTrackerRepository.findOne({
      user,
      event: group.currentEvent,
    });

    if (!evTracker) {
      const newTracker = await this.createEventTracker(
        user,
        await group.currentEvent.load(),
      );

      return newTracker;
    }
    return evTracker;
  }

  /** Saves an event tracker */
  async saveTracker(tracker: EventTracker) {
    await this.eventTrackerRepository.persistAndFlush(tracker);
  }

  async createNew(event: EventBase) {
    const chal = this.challengeRepository.create({
      eventIndex: 0,
      name: 'New challenge',
      description: 'McGraw Tower',
      imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/5/5f/CentralAvenueCornell2.jpg',
      latitude: 42.44755580740012,
      longitude: -76.48504614830019,
      awardingRadius: 50,
      closeRadius: 100,
      completions: [],
      linkedEvent: event,
    });

    await this.challengeRepository.persistAndFlush(chal);

    return chal;
  }

  async makeDefaultEvent() {
    const ev = this.eventsRepository.create({
      name: 'Default Event',
      description: 'Default Event',
      requiredMembers: 1,
      minimumScore: 1,
      skippingEnabled: true,
      isDefault: true,
      rewardType: EventRewardType.PERPETUAL,
      indexable: false,
      time: new Date('2060'),
      rewards: [],
      challenges: [],
    });

    const chal = await this.createNew(ev);
    ev.challenges.set([chal]);

    await this.eventsRepository.persistAndFlush(ev);

    return ev;
  }

  async deleteAllEventTrackers(user: User) {
    // Delete all event trackers for user
    await this.eventTrackerRepository
      .createQueryBuilder()
      .delete()
      .where({ user });
    this.em.clear();
  }
}
