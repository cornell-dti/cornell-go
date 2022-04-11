import { InjectRepository } from '@mikro-orm/nestjs';
import { EntityRepository } from '@mikro-orm/postgresql';
import { Injectable } from '@nestjs/common';
import { EventReward } from '../model/event-reward.entity';
import { User } from '../model/user.entity';

@Injectable()
export class RewardService {
  constructor(
    @InjectRepository(EventReward)
    private rewardRepository: EntityRepository<EventReward>,
  ) {}

  /** Get rewards that are in ids and owned by the user */
  async getRewardsForUser(user: User, ids: string[]): Promise<EventReward[]> {
    return await this.rewardRepository.find({ id: ids, claimingUser: user });
  }

  /** Get rewards that are in ids and not owned by the user */
  async getRewardsNotForUser(
    user: User,
    ids: string[],
  ): Promise<EventReward[]> {
    return await this.rewardRepository.find({
      id: ids,
      $not: { claimingUser: user },
    });
  }
}
