import {
  Column,
  Entity,
  Index,
  ManyToMany,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { Challenge } from './challenge.entity';
import { EventReward } from './event-reward.entity';

/** Enum describing how this event will reward players */
export enum EventRewardType {
  /** Event ends at specific time, top N people are rewarded */
  LIMITED_TIME_EVENT = 'limited_time_event',
  /** N people who complete event first will be rewarded equally, will be advertised as upcoming */
  WIN_ON_COMPLETION = 'win_on_completion',
  /** N people who complete event first will be rewarded based on their time to completion, will be advertised as upcoming */
  RACE_TO_WIN = 'race_to_win',
  /** Perpetual event with no rewards */
  NO_REWARDS = 'no_rewards',
}

@Entity()
export class EventBase {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  /** Minimum number of members to complete this event */
  @Column()
  minMembers!: number;

  /** If the event allows saving uncompleted challenges for later */
  @Column()
  skippingEnabled!: boolean;

  /** True if the event is considered the default option */
  @Column()
  @Index()
  isDefault!: boolean;

  /** If true, then the last challenge is considered a star challenge */
  @Column()
  hasStarChallenge!: boolean;

  @Column()
  name!: string;

  @Column()
  description!: string;

  /** Describes how event is rewarded */
  @Column({
    type: 'enum',
    enum: EventRewardType,
    default: EventRewardType.NO_REWARDS,
  })
  rewardType!: EventRewardType;

  /** True if the event is indexable by a search */
  indexable!: boolean;

  /** Describes end time for limited time events and begin time for others */
  @Column()
  time!: Date;

  /** Describes the top N people to be rewarded */
  @Column()
  topCount!: number;

  /** Describes the rewards */
  @OneToMany(() => EventReward, rew => rew.containingEvent)
  rewards!: EventReward[];

  /** Ordered list of challenges */
  @ManyToMany(() => Challenge)
  challenges!: Challenge[];

  /** Amount of entities in the "challenges" field (update whenever that changes) */
  @Column()
  challengeCount!: number;
}
