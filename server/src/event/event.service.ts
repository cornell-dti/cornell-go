import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Point } from 'geojson';
import { Challenge } from '../model/challenge.entity';
import { EventProgress } from '../model/event-progress.entity';
import { EventReward } from '../model/event-reward.entity';
import { User } from '../model/user.entity';
import { EventBase, EventRewardType } from '../model/event-base.entity';

@Injectable()
export class EventService {
  constructor(
    @InjectRepository(EventBase)
    private eventsRepository: Repository<EventBase>,
    @InjectRepository(EventProgress)
    private eventProgressRepository: Repository<EventProgress>,
  ) {}

  /** Get events by ids */
  async getEventsByIds(ids: string[], loadRewards: boolean) {
    return await this.eventsRepository.findByIds(ids, {
      relations: loadRewards ? [] : ['rewards'],
    });
  }

  /** Get top players for event */
  async getTopProgressForEvent(eventId: string, offset: number, count: number) {
    return await this.eventProgressRepository.find({
      order: {
        eventScore: 'DESC',
      },
      relations: ['user'],
      select: ['user'],
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

    let progress: EventProgress = this.eventProgressRepository.create({
      eventScore: 0,
      isPlayerRanked: true,
      cooldownMinimum: new Date(),
      event: defaultEvent,
      currentChallenge: closestChallenge,
      completed: [],
      user,
    });

    await this.eventProgressRepository.save(progress);

    return progress;
  }
}
