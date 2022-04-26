import {
  Collection,
  Entity,
  Enum,
  Index,
  ManyToMany,
  OneToMany,
  PrimaryKey,
  Property,
} from '@mikro-orm/core';
import { v4 } from 'uuid';
import { Challenge } from './challenge.entity';
import { EventReward } from './event-reward.entity';
import { RestrictionGroup } from './restriction-group.entity';

/** Enum describing how this event will reward players */
export enum EventRewardType {
  /** Event ends at specific time, top N people are rewarded */
  LIMITED_TIME_EVENT = 'limited_time_event',
  /** Perpetual event with an infinite or null reward */
  PERPETUAL = 'perpetual',
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

  /** Describes end time for the event */
  @Property()
  time!: Date;

  /** Describes minimum score to get a reward */
  @Property()
  minimumScore = 1;

  /** Describes the rewards */
  @OneToMany(() => EventReward, rew => rew.containingEvent, {
    orphanRemoval: true,
  })
  rewards = new Collection<EventReward>(this);

  /** Ordered list of challenges */
  @OneToMany({
    entity: () => Challenge,
    mappedBy: 'linkedEvent',
    orderBy: { eventIndex: 'asc' },
    orphanRemoval: true,
  })
  challenges = new Collection<Challenge>(this);

  @ManyToMany(() => RestrictionGroup, rg => rg.allowedEvents)
  allowedIn = new Collection<RestrictionGroup>(this);
}
