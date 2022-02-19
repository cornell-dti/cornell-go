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
  ) {
    eventsRepository
      .findOneOrFail({ isDefault: true })
      .then(() => {})
      .catch(() => this.makeDefaultEvent());
  }

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
        id: eventId,
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
        skippingEnabled: skippable,
      },
      {
        orderBy: sortBy,
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
    const defaultEvent = await this.eventsRepository
      .createQueryBuilder('ev')
      .select(['ev.*'])
      .where({ isDefault: true })
      .joinAndSelect('ev.challenges', 'chal')
      .andWhere(
        `((chal.latitude - ${+lat})^2 + (chal.longitude - ${+long})^2) > 0.000000128205 * chal.close_radius * chal.close_radius`,
      )
      .orderBy({
        [`((chal.latitude - ${+lat})^2 + (chal.longitude - ${+long})^2)`]:
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

  /** Get a player's event trackers by event id */
  async getEventTrackersByEventId(user: User, eventIds: string[]) {
    return await this.eventTrackerRepository.find({
      user,
      event: { id: eventIds },
    });
  }

  /** Gets a player's event tracker based on group */
  async getCurrentEventTrackerForUser(user: User) {
    const member = await user.groupMember?.load();
    const group = await member?.group.load();

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
      description: 'New challenge',
      imageUrl: '',
      latitude: 0,
      longitude: 0,
      awardingRadius: 0,
      closeRadius: 0,
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
      minMembers: 1,
      skippingEnabled: true,
      isDefault: true,
      hasStarChallenge: false,
      rewardType: EventRewardType.NO_REWARDS,
      indexable: false,
      time: new Date(),
      topCount: 1,
      rewards: [],
      challenges: [],
      challengeCount: 0,
    });

    const chal = await this.createNew(ev);
    ev.challenges.set([chal]);

    await this.eventsRepository.persistAndFlush(ev);

    return ev;
  }
}
