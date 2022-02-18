import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Point } from 'geojson';
import { Challenge } from '../model/challenge.entity';
import { EventTracker } from '../model/event-tracker.entity';
import { EventReward } from '../model/event-reward.entity';
import { User } from '../model/user.entity';
import { EventBase, EventRewardType } from '../model/event-base.entity';
import { UserService } from '../user/user.service';
import { ChallengeService } from 'src/challenge/challenge.service';

@Injectable()
export class EventService {
  constructor(
    private userService: UserService,
    @InjectRepository(EventBase)
    private eventsRepository: Repository<EventBase>,
    @InjectRepository(EventTracker)
    private eventTrackerRepository: Repository<EventTracker>,
    @Inject(forwardRef(() => ChallengeService))
    private challengeService: ChallengeService,
  ) {
    eventsRepository
      .findOneOrFail({ isDefault: true })
      .then(() => {})
      .catch(() => {
        this.makeDefaultEvent();
      });
  }

  /** Get events by ids */
  async getEventsByIds(ids: string[], loadRewards: boolean) {
    return await this.eventsRepository.findByIds(ids, {
      relations: loadRewards ? [] : ['rewards'],
    });
  }

  /** Get top players for event */
  async getTopTrackerForEvent(
    eventId: string,
    offset: number,
    count: number,
    onlyUser: boolean,
  ) {
    return await this.eventTrackerRepository.find({
      order: {
        eventScore: 'DESC',
      },
      relations: ['user', 'event'],
      select: onlyUser ? undefined : ['user'],
      where: { eventId },
      skip: offset,
      take: count,
    });
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
    const events = await this.eventsRepository.find({
      where: {
        indexable: true,
        rewardType: rewardTypes && In(rewardTypes),
        skippingEnabled: skippable,
      },
      select: ['id'],
      order: sortBy,
      skip: offset,
      take: count,
    });

    return events.map(ev => ev.id);
  }

  /** Verifies that a challenge is in an event */
  async isChallengeInEvent(challengeId: string, eventId: string) {
    const resultCount = await this.eventsRepository
      .createQueryBuilder()
      .where({ id: eventId })
      .relation(Challenge, 'challenges')
      .select()
      .where({ id: challengeId })
      .getCount();
    return resultCount > 0;
  }

  /** Creates an event tracker with the closest challenge as the current one */
  async createDefaultEventTracker(user: User, lat: number, long: number) {
    let player: Point = {
      type: 'Point',
      coordinates: [long, lat],
    };

    let defaultEvent = await this.eventsRepository.findOneOrFail({
      isDefault: true,
    });

    let closestChallenge = await this.eventsRepository
      .createQueryBuilder()
      .relation(Challenge, 'challenges')
      .of(defaultEvent)
      .select()
      .where(
        'not ST_DWITHIN(location, ST_SetSRID(ST_GeomFromGeoJSON(:player), ST_SRID(location)), closeRadius, false)',
      )
      .orderBy(
        'ST_Distance(location, ST_SetSRID(ST_GeomFromGeoJSON(:player), ST_SRID(location)))',
        'ASC',
      )
      .setParameter('player', JSON.stringify(player))
      .getOneOrFail();

    let progress: EventTracker = this.eventTrackerRepository.create({
      eventScore: 0,
      isPlayerRanked: true,
      cooldownMinimum: new Date(),
      event: defaultEvent,
      currentChallenge: closestChallenge,
      completed: [],
      user,
    });

    await this.eventTrackerRepository.save(progress);

    return progress;
  }

  /** Get a player's event trackers by event id */
  async getEventTrackersByEventId(user: User, eventIds: string[]) {
    return await this.eventTrackerRepository
      .createQueryBuilder('tracker')
      .where('tracker.userId = :userId', { userId: user.id })
      .innerJoinAndSelect('tracker.event', 'event', 'event.id IN (:...evIds)')
      .leftJoinAndSelect('tracker.currentChallenge', 'currentChallenge')
      .leftJoinAndSelect('tracker.completed', 'completed')
      .leftJoinAndSelect('completed.challenge', 'challenge')
      .setParameter('evIds', eventIds)
      .getMany();
  }

  /** Gets a player's event tracker based on group */
  async getCurrentEventTrackerForUser(user: User) {
    return await this.eventTrackerRepository
      .createQueryBuilder('tracker')
      .innerJoinAndSelect('tracker.user', 'user', 'user.id = :userId')
      .leftJoinAndSelect('tracker.event', 'trackerEvent')
      .leftJoinAndSelect('user.groupMember', 'groupMember')
      .leftJoinAndSelect('groupMember.group', 'group')
      .leftJoinAndSelect('group.currentEvent', 'event')
      .where('event.id = trackerEvent.id')
      .setParameter('userId', user.id)
      .getOneOrFail();
  }

  /** Saves an event tracker */
  async saveTracker(tracker: EventTracker) {
    await this.eventTrackerRepository.save(tracker);
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

    const chal = await this.challengeService.createNew(ev);
    ev.challenges = [chal];

    await this.eventsRepository.save(ev);

    return ev;
  }
}
