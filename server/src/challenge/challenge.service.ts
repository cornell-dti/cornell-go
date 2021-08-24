import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Challenge } from '../model/challenge.entity';
import { EventBase } from '../model/event-base.entity';
import { EventTracker } from '../model/event-tracker.entity';
import { PrevChallenge } from '../model/prev-challenge.entity';
import { User } from '../model/user.entity';

@Injectable()
export class ChallengeService {
  constructor(
    @InjectRepository(Challenge)
    private challengeRepository: Repository<Challenge>,
  ) {}

  async getChallengesByIdsWithPrevChallenge(
    user: User,
    ids: string[],
  ): Promise<Challenge[]> {
    return await this.challengeRepository
      .createQueryBuilder()
      .whereInIds(ids)
      .leftJoinAndSelect(
        'completions',
        'prevChallenge',
        'prevChallenge.ownerId = :userId',
        { userId: user.id },
      )
      .getMany();
  }
}
