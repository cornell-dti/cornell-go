import {
  Collection,
  Entity,
  Enum,
  Index,
  OneToMany,
  PrimaryKey,
  Property,
} from '@mikro-orm/core';
import { v4 } from 'uuid';
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
  /** Perpetual event with an infinite or null reward */
  PERPETUAL = 'no_rewards',
}

@Entity()
export class EventBase {
  @PrimaryKey()
  id = v4();

  /** Required amount of members to successfully complete this event, -1 for any amount */
  @Property()
  requiredMembers!: number;

  /** If the event allows saving uncompleted challenges for later */
  @Property()
  skippingEnabled!: boolean;

  /** True if the event is considered the default option */
  @Property()
  @Index()
  isDefault!: boolean;

  /** If true, then the challenge with index 9999 is considered a star challenge */
  @Property()
  hasStarChallenge!: boolean;

  @Property()
  name!: string;

  @Property()
  description!: string;

  /** Describes how event is rewarded */
  @Enum(() => EventRewardType)
  rewardType!: EventRewardType;

  /** True if the event is indexable by a search */
  @Property()
  indexable!: boolean;

  /** Describes end time for limited time events and begin time for others */
  @Property()
  time!: Date;

  /** Describes the top N people to be rewarded */
  @Property()
  topCount!: number;

  /** Describes the rewards */
  @OneToMany(() => EventReward, rew => rew.containingEvent)
  rewards = new Collection<EventReward>(this);

  /** Ordered list of challenges */
  @OneToMany({
    entity: () => Challenge,
    mappedBy: 'linkedEvent',
    orderBy: { eventIndex: 'asc' },
  })
  challenges = new Collection<Challenge>(this);

  /** Amount of entities in the "challenges" field (update whenever that changes) */
  @Property()
  challengeCount!: number;
}
