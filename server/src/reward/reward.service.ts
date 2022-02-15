import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EventReward } from '../model/event-reward.entity';
import { User } from '../model/user.entity';

@Injectable()
export class RewardService {
  constructor(
    @InjectRepository(EventReward)
    private rewardRepository: Repository<EventReward>,
  ) {}

  /** Get rewards that are in ids and owned by the user */
  async getRewardsForUser(user: User, ids: string[]) {
    return await this.rewardRepository.findByIds(ids, {
      where: { claimingUser: user },
      loadRelationIds: true,
    });
  }

  /** */
}
