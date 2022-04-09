import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { Point } from 'geojson';
import { Challenge } from '../model/challenge.entity';
import { EventTracker } from '../model/event-tracker.entity';
import { EventReward } from '../model/event-reward.entity';
import { User } from '../model/user.entity';
import { EventBase, EventRewardType } from '../model/event-base.entity';
import { UserService } from '../user/user.service';
import { ChallengeService } from 'src/challenge/challenge.service';
import { InjectRepository } from '@mikro-orm/nestjs';
import { EntityRepository } from '@mikro-orm/postgresql';

@Injectable()
export class EventService {
  constructor(
    private userService: UserService,
    @InjectRepository(EventBase)
    private eventsRepository: EntityRepository<EventBase>,
    @InjectRepository(EventTracker)
    private eventTrackerRepository: EntityRepository<EventTracker>,
    @InjectRepository(Challenge)
    private challengeRepository: EntityRepository<Challenge>,
  ) {}

  /** Get events by ids */
  async getEventsByIds(ids: string[]): Promise<EventBase[]> {
    return await this.eventsRepository.find({ id: { $in: ids } });
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
  ) {
    const events = await this.eventsRepository.find(
      {
        indexable: true,
        rewardType: rewardTypes && { $in: rewardTypes },
        ...(skippable && { skippingEnabled: true }),
      },
      {
        offset,
        limit: count,
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

    let progress: EventTracker = this.eventTrackerRepository.create({
      eventScore: 0,
      isPlayerRanked: true,
      cooldownMinimum: new Date(),
      event: defaultEvent,
      currentChallenge: closestChallenge,
      completed: [],
      user,
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
    let closestChallenge = event.challenges[0];

    let progress: EventTracker = this.eventTrackerRepository.create({
      eventScore: 0,
      isPlayerRanked: true,
      cooldownMinimum: new Date(),
      event: event,
      currentChallenge: closestChallenge,
      completed: [],
      user,
    });

    await this.eventTrackerRepository.persistAndFlush(progress);

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
    const group = await user.group?.load();

    return await this.eventTrackerRepository.findOneOrFail({
      user,
      event: group?.currentEvent,
    });
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
      awardingRadius: 10,
      closeRadius: 50,
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
      skippingEnabled: true,
      isDefault: true,
      rewardType: EventRewardType.PERPETUAL,
      indexable: false,
      time: new Date(),
      rewards: [],
      challenges: [],
    });

    const chal = await this.createNew(ev);
    ev.challenges.set([chal]);

    await this.eventsRepository.persistAndFlush(ev);

    return ev;
  }
}
