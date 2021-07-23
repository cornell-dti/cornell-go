import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Point } from 'geojson';
import { Challenge } from '../model/challenge.entity';
import { EventProgress } from '../model/event-progress.entity';
import { EventReward } from '../model/event-reward.entity';
import { User } from '../model/user.entity';
import { EventBase } from '../model/event-base.entity';

@Injectable()
export class EventsService {
  constructor(
    @InjectRepository(EventBase)
    private eventsRepository: Repository<EventBase>,
    @InjectRepository(EventProgress)
    private eventProgressRepository: Repository<EventProgress>,
    @InjectRepository(EventReward)
    private eventRewardsRepository: Repository<EventReward>,
  ) {}

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

    let progress: EventProgress = Object.assign(new EventProgress(), {
      id: -1,
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
